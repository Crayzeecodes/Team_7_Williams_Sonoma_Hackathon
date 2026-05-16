"""
FastAPI backend for Williams-Sonoma AI Room Analysis.

Receives room images + user preferences from iOS app,
calls Google Gemini API for intelligent room analysis,
returns structured product recommendations.

Usage:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000
"""

import base64
import io
import json
import logging
import os
from typing import Optional

from dotenv import load_dotenv

# Load .env file (picks up GEMINI_API_KEY)
load_dotenv()

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai
import PIL.Image
from supabase import create_client, Client
import uuid
from datetime import datetime, timezone

# ── Configure Gemini & Supabase ───────────────────────────
genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
model = genai.GenerativeModel("gemini-2.5-flash")

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY", "")

# Initialize Supabase client only if keys are present
if SUPABASE_URL and SUPABASE_KEY:
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
else:
    supabase = None

# ── Logging ──────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("room_analyzer")

# ── FastAPI App ──────────────────────────────────────────
app = FastAPI(
    title="WS Room Analyzer",
    description="AI-powered room analysis for Williams-Sonoma",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request / Response Models ────────────────────────────
class Preferences(BaseModel):
    category: str
    size: str
    budget_max: float
    style_vibe: str


class RoomAnalyzeRequest(BaseModel):
    images: list[str]  # base64-encoded JPEG strings
    preferences: Preferences


class RoomAnalysisResult(BaseModel):
    room_type: str
    detected_style: str
    dominant_colors: list[str]
    dominant_materials: list[str]
    recommended_style_tags: list[str]
    recommended_categories: list[str]
    price_max: float
    size_preference: str
    reasoning: str
    negative_categories: list[str]
    recommended_products: list[dict] = []


# ── Gemini Prompt ────────────────────────────────────────
ANALYSIS_PROMPT = """
You are a world-class interior design AI for Williams-Sonoma.

Analyze the provided room image(s) and user preferences carefully.

User preferences:
- Shopping for: {category}
- Size preference: {size}
- Budget max: ${budget_max}
- Style: {style_vibe}

Your job:
1. Identify the room type precisely (kitchen, living_room, dining_room, bedroom, bathroom, outdoor_patio).
2. Deeply analyze the visual foundation of the room: look at the background colors, the wall paint, any wallpaper patterns, flooring, and dominant textures.
3. Identify the overall design style (e.g., minimalist, rustic, farmhouse, mid-century modern).
4. Reason about what would actually *look good* in this exact space. Would a certain material clash with the wallpaper? Would a specific color pop beautifully against the wall paint?
5. Based on this visual harmony, recommend Williams-Sonoma product categories that would genuinely complement the room. Use these exact category names where applicable: Cookware, Knives & Cutlery, Bakeware, Electrics, Kitchen Tools, Coffee & Tea, Outdoor & BBQ, Tabletop & Bar, Food & Pantry, Storage & Organization, Cleaning, Gifts & Registry.
6. Return structured JSON only — no prose, no markdown, no explanation.

Return ONLY this JSON:
{{
  "room_type": "living_room",
  "detected_style": "modern",
  "dominant_colors": ["warm white", "oak wood", "charcoal"],
  "dominant_materials": ["wood", "linen", "glass"],
  "recommended_style_tags": ["modern", "minimalist", "warm"],
  "recommended_categories": ["Tabletop & Bar", "Storage & Organization"],
  "price_max": {budget_max},
  "size_preference": "{size}",
  "reasoning": "This modern living room with warm oak tones and linen textures would be complemented by clean-lined tabletop pieces and natural fiber textiles",
  "negative_categories": ["Cookware", "Bakeware"]
}}
"""


# ── Health Check ─────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "service": "room-analyzer"}


# ── Room Analysis Endpoint ───────────────────────────────
@app.post("/room/analyze", response_model=RoomAnalysisResult)
async def analyze_room(request: RoomAnalyzeRequest):
    """
    Accepts room images (base64) + user preferences,
    calls Google Gemini API for analysis, returns structured JSON.
    """
    if not request.images:
        raise HTTPException(status_code=400, detail="At least one image is required.")

    logger.info(
        f"Room analysis request: {len(request.images)} image(s), "
        f"category={request.preferences.category}, "
        f"style={request.preferences.style_vibe}"
    )

    try:
        # Build Gemini content: images + prompt
        content_parts = []

        for img_b64 in request.images[:4]:  # Max 4 images
            image_bytes = base64.b64decode(img_b64)
            image = PIL.Image.open(io.BytesIO(image_bytes))
            content_parts.append(image)

        # Add analysis prompt
        prompt = ANALYSIS_PROMPT.format(
            category=request.preferences.category,
            size=request.preferences.size,
            budget_max=request.preferences.budget_max,
            style_vibe=request.preferences.style_vibe,
        )
        content_parts.append(prompt)

        # Call Gemini API
        response = model.generate_content(content_parts)
        raw_text = response.text.strip()

        # Handle potential markdown wrapping
        if raw_text.startswith("```"):
            raw_text = raw_text.split("\n", 1)[1]
            if raw_text.endswith("```"):
                raw_text = raw_text[:-3].strip()

        result = json.loads(raw_text)
        logger.info(f"Analysis complete: room_type={result.get('room_type')}")

        # ── Query Supabase for Products ───────────────────────────
        recommended_cats = result.get("recommended_categories", [])
        price_max = result.get("price_max", 10000.0)
        
        mapped_products = []
        
        if supabase is not None:
            try:
                # Build Supabase query
                query = supabase.table('products').select('*')
                
                # Filter by recommended categories if Gemini provided them
                if recommended_cats:
                    # In Supabase/PostgREST, we use .in_() for array inclusion
                    query = query.in_('category', recommended_cats)
                    
                # Filter by maximum budget
                query = query.lte('price', price_max).limit(12)
                
                # Execute query
                db_response = query.execute()
                supabase_docs = db_response.data
                
                # Map Supabase rows to iOS WSProduct format
                for doc in supabase_docs:
                    
                    # Convert Supabase numeric/arrays safely
                    price_val = float(doc.get("price") or 0.0)
                    stars_val = float(doc.get("stars") or 0.0)
                    images_val = doc.get("images") or []
                    
                    mapped_products.append({
                        "id": str(doc.get("id")),
                        "name": doc.get("name", "Unknown Product"),
                        "brand": "Williams Sonoma",
                        "category": doc.get("category", "General"),
                        "subcategory": None,
                        "price": price_val,
                        "sale_price": None,
                        "image_names": images_val,
                        "rating": stars_val,
                        "review_count": 0,
                        "description": doc.get("description", ""),
                        "specs": {},
                        "is_on_sale": False,
                        "is_featured": False,
                        "is_new_arrival": False,
                        "occasions": [],
                        "collection_name": None,
                        "stock_count": 100,
                        "gift_packaging_available": False,
                        "gift_packaging_price": None,
                        "colors": [],
                        "sizes": [],
                        "created_at": doc.get("created_at") or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                    })
            except Exception as e:
                logger.error(f"Supabase query error: {e}")
                # Don't fail the entire analysis if DB fails, just return empty products
        else:
            logger.warning("Supabase credentials not set, skipping product fetch")
            
        result["recommended_products"] = mapped_products

        return RoomAnalysisResult(**result)

    except json.JSONDecodeError as e:
        logger.error(f"JSON parse error: {e}, raw: {raw_text[:200]}")
        raise HTTPException(status_code=502, detail="Failed to parse AI response.")
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        raise HTTPException(status_code=502, detail=f"AI analysis failed: {str(e)}")

# ── Fetch All Products Endpoint ──────────────────────────
@app.get("/products")
async def get_all_products():
    """
    Fetches all products from Supabase and maps them to the iOS WSProduct schema.
    Used by the main Shop tab.
    """
    mapped_products = []
    
    if supabase is not None:
        try:
            # Fetch all products (limit 50 to avoid massive payloads)
            db_response = supabase.table('products').select('*').limit(50).execute()
            supabase_docs = db_response.data
            
            for doc in supabase_docs:
                price_val = float(doc.get("price") or 0.0)
                stars_val = float(doc.get("stars") or 0.0)
                images_val = doc.get("images") or []
                
                mapped_products.append({
                    "id": str(doc.get("id")),
                    "name": doc.get("name", "Unknown Product"),
                    "brand": "Williams Sonoma",
                    "category": doc.get("category", "General"),
                    "subcategory": None,
                    "price": price_val,
                    "sale_price": None,
                    "image_names": images_val,
                    "rating": stars_val,
                    "review_count": 0,
                    "description": doc.get("description", ""),
                    "specs": {},
                    "is_on_sale": False,
                    "is_featured": False,
                    "is_new_arrival": False,
                    "occasions": [],
                    "collection_name": None,
                    "stock_count": 100,
                    "gift_packaging_available": False,
                    "gift_packaging_price": None,
                    "colors": [],
                    "sizes": [],
                    "created_at": doc.get("created_at") or datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
                })
        except Exception as e:
            logger.error(f"Supabase fetch all products error: {e}")
            raise HTTPException(status_code=500, detail="Failed to fetch products from Supabase")
            
    return mapped_products
