const mongoose = require("mongoose");
const fs = require("fs");
const path = require("path");
require("dotenv").config();

const Product = require("./models/Product");

const LOCAL_IMAGES_BY_SKU = {
  "greenpan-reserve-pro-10pc": ["/cookware-set1.jpg", "/cookware-set2.jpg", "/cookware-set3.jpg"],
  "all-clad-d3-10pc": ["/cookware-set2.jpg", "/cookware-set3.jpg", "/cookware-set4.jpg"],
  "le-creuset-signature-dutch-oven-5qt": ["/cookware-oven1.jpg", "/cookware-oven2.jpg", "/cookware-oven3.jpg"],
  "staub-cast-iron-braiser-3.5qt": ["/cookware-oven2.jpg", "/cookware-oven3.jpg", "/cookware-cooker1.jpg"],
  "mauviel-m-steel-carbon-skillet-12in": ["/cookware-frypan1.jpg", "/cookware-frypan2.jpg", "/cookware-frypan3.jpg"],
  "ws-stainless-7pc-gadget-set": ["/cookstools-utensil1.jpg", "/cookstools-mescup1.jpg", "/cookstools-snp1.jpg"],
  "oxo-good-grips-mandoline": ["/cookstools-snp1.jpg", "/cookstools-snp2.jpg", "/cookstools-utensil1.jpg"],
  "microplane-premium-classic-zester": ["/cookstools-snp2.jpg", "/cookstools-utensil1.jpg", "/cookstools-mescup2.jpg"],
  "ws-instant-read-thermometer": ["/cookstools-snp1.jpg", "/cookstools-snp2.jpg"],
  "ws-pro-kitchen-scale": ["/cookstools-mescup1.jpg", "/cookstools-mescup2.jpg", "/cookstools-mescup3.jpg"],
  "shun-classic-8in-chefs-knife": ["/cutlery-knifeset1.jpg", "/cutlery-knifeset2.jpg", "/cutlery-knifeset3.jpg"],
  "wusthof-classic-7pc-block-set": ["/cutlery-knifeset2.jpg", "/cutlery-knifeset3.jpg", "/cutlery-knifesharp1.jpg"],
  "global-g2-8in-chefs-knife": ["/cutlery-knifeset3.jpg", "/cutlery-knifeset1.jpg"],
  "ws-pro-honing-steel-12in": ["/cutlery-knifesharp1.jpg", "/cutlery-knifesharp2.jpg", "/cutlery-knifesharp3.jpg"],
  "breville-barista-express-espresso": ["/food-coffee1.jpg", "/food-coffee2.jpg", "/food-coffee3.jpg"],
  "kitchenaid-artisan-stand-mixer-5qt": ["/bakeware-set1.jpg", "/bakeware-set2.jpg", "/bakeware-set3.jpg"],
  "vitamix-a3500-ascent-blender": ["/electrics-blender1.jpg", "/electrics-blender2.jpg", "/electrics-blender3.jpg"],
  "cuisinart-food-processor-14cup": ["/electrics-blender2.jpg", "/electrics-blender3.jpg"],
  "breville-smart-oven-air-fryer-pro": ["/electrics-pizzaoven1.jpg", "/electrics-pizzaoven2.jpg", "/electrics-pizzaoven3.jpg"],
  "nespresso-vertuo-next-coffee-maker": ["/food-coffee2.jpg", "/food-coffee3.jpg", "/food-coffee1.jpg"],
  "nordic-ware-half-sheet-pan-2pk": ["/bakeware-cookiesheet1.jpg", "/bakeware-cookiesheet2.jpg", "/bakeware-cookiesheet3.jpg"],
  "williams-sonoma-goldtouch-9x13-pan": ["/bakeware-set1.jpg", "/bakeware-set2.jpg", "/bakeware-set3.jpg"],
  "emile-henry-pie-dish-9in": ["/bakeware-set2.jpg", "/bakeware-set3.jpg"],
  "chicago-metallic-muffin-pan-12cup": ["/bakeware-muffinpan1.jpg", "/bakeware-muffinpan2.jpg", "/bakeware-muffinpan3.jpg"],
  "ws-peppercorn-medley-grinder": ["/food-coffee1.jpg", "/food-dessertmix1.jpg"],
  "ws-hot-cocoa-mix-classic": ["/food-dessertmix1.jpg", "/food-dessertmix2.jpg", "/food-dessertmix3.jpg"],
  "ws-calabrian-chili-oil": ["/cookstools-oil1.jpg", "/cookstools-utensil1.jpg"],
  "ws-vanilla-bean-paste": ["/food-dessertmix2.jpg", "/food-dessertmix3.jpg"],
  "riedel-performance-cabernet-2pk": ["/img236m.jpg"],
  "open-kitchen-marble-cheese-board": ["/cutlery-cuttingboard1.jpg", "/cutlery-cuttingboard2.jpg", "/cutlery-cuttingboard3.jpg"],
  "cocktail-kingdom-bar-tool-set-5pc": ["/img236m.jpg", "/cookstools-utensil1.jpg"],
  "ws-hammered-copper-moscow-mule-mugs-2pk": ["/img236m.jpg", "/img95m.jpg"],
  "simplehuman-sensor-soap-pump-9oz": ["/cookstools-oil1.jpg"],
  "ws-weck-canning-jar-set-6pc": ["/food-dessertmix1.jpg", "/food-dessertmix2.jpg"],
  "ws-linen-apron-natural": ["/cookstools-utensil1.jpg"],
  "weber-spirit-ii-e310-gas-grill": ["/cookware-frypan1.jpg", "/cookware-frypan2.jpg"],
  "traeger-ironwood-xl-pellet-grill": ["/electrics-pizzaoven1.jpg", "/electrics-pizzaoven2.jpg"],
  "lodge-cast-iron-grill-pan-10.5in": ["/cookware-frypan2.jpg", "/cookware-frypan3.jpg"],
  "ws-butcher-block-kitchen-island": ["/cutlery-cuttingboard1.jpg", "/cutlery-cuttingboard2.jpg"],
  "ws-bakers-rack-steel": ["/bakeware-set1.jpg"],
  "ws-ultimate-baking-gift-box": ["/food-dessertmix1.jpg", "/food-dessertmix2.jpg", "/food-dessertmix3.jpg"],
  "ws-global-grilling-spice-set": ["/food-dessertmix2.jpg", "/food-dessertmix3.jpg"],
  "ws-handcrafted-pasta-making-kit": ["/electrics-pastamachine1.jpg", "/electrics-pastamachine2.jpg", "/electrics-pastamachine3.jpg"],
  "ws-nordic-ware-holiday-bundt-pan": ["/bakeware-set3.jpg", "/bakeware-muffinpan1.jpg"],
  "ws-gingerbread-house-kit": ["/food-dessertmix3.jpg", "/food-dessertmix1.jpg"],
  "hestan-nanobond-skillet-12in": ["/cookware-frypan3.jpg", "/cookware-frypan1.jpg"],
  "wolf-gourmet-precision-griddle": ["/electrics-pizzaoven2.jpg", "/electrics-pizzaoven3.jpg"],
  "all-clad-ha1-nonstick-fry-pan-10in-sale": ["/cookware-frypan1.jpg", "/cookware-frypan2.jpg"],
  "cuisinart-ice-cream-maker-sale": ["/food-icecream1.jpg", "/food-icecream2.jpg", "/food-icecream3.jpg"],
};

function localImagesForProduct(product) {
  return LOCAL_IMAGES_BY_SKU[product.skuId] || product.images || [];
}

// ─────────────────────────────────────────────
// 50+ Williams-Sonoma–style products across all
// categories defined in your nav:
//   New | Cookware | Cooks' Tools | Cutlery |
//   Electrics | Bakeware | Food | Tabletop & Bar |
//   Home Essentials | Outdoor & Garden | Furniture |
//   Holidays | Gifts | Sale
// ─────────────────────────────────────────────

const WS_PRODUCTS = [

  // ── COOKWARE ────────────────────────────────
  {
    skuId: "greenpan-reserve-pro-10pc",
    name: "GreenPan™ Reserve Pro Ceramic Nonstick 10-Piece Cookware Set",
    description:
      "World-class performance meets sleek style in the GreenPan Reserve Pro collection. The pans feature a tough hard-anodized body and a diamond-infused Thermolon ceramic nonstick coating that's free of PFAS, PFOA, lead and cadmium.",
    price: 399.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202603/0108/greenpan-reserve-pro-ceramic-nonstick-10-piece-cookware-se-d.jpg",
    ],
    category: "Cookware",
    specs: [
      "Set includes: 8\" & 11\" fry pans, 2-qt & 3-qt saucepans with lids, 3-qt sauté pan with lid, 5-qt Dutch oven with lid",
      "Thermolon Diamond Advanced ceramic nonstick – PFAS-free",
      "Hard-anodized aluminum body for even heat distribution",
      "Oven & broiler safe to 600°F (glass lids to 425°F)",
      "Compatible with all stovetops including induction",
      "Dishwasher safe",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "all-clad-d3-10pc",
    name: "All-Clad D3 Stainless Steel 10-Piece Cookware Set",
    description:
      "Crafted in the USA, All-Clad D3 features tri-ply bonded construction—stainless steel, aluminum core, stainless steel—delivering fast, even heating from rim to rim.",
    price: 699.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202425/0001/all-clad-d3-stainless-steel-10-piece-d.jpg",
    ],
    category: "Cookware",
    specs: [
      "10-piece set: 8\" & 10\" fry pans, 2-qt & 3-qt saucepans with lids, 3-qt sauté pan with lid, 8-qt stockpot with lid",
      "Tri-ply bonded stainless-steel/aluminum/stainless-steel construction",
      "Starburst finish interior resists sticking and is easy to clean",
      "Oven and broiler safe to 600°F",
      "Dishwasher safe; made in the USA",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "le-creuset-signature-dutch-oven-5qt",
    name: "Le Creuset Signature Round Dutch Oven, 5.5 Qt.",
    description:
      "The Le Creuset Signature Dutch Oven is the gold standard of braising. Its enameled cast-iron construction delivers unmatched heat retention for slow braises, soups and breads.",
    price: 459.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0042/le-creuset-signature-enameled-cast-iron-round-dutch-oven-d.jpg",
    ],
    category: "Cookware",
    specs: [
      "5.5-qt capacity; fits a whole chicken or large roast",
      "Enameled cast iron retains and distributes heat evenly",
      "Tight-fitting lid seals in moisture and nutrients",
      "Colorful exterior enamel resists chipping and cracking",
      "Oven safe to 500°F; dishwasher safe",
      "Available in 15+ colors",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "staub-cast-iron-braiser-3.5qt",
    name: "Staub Cast Iron Braiser, 3.5 Qt.",
    description:
      "The Staub braiser's wide, shallow shape is ideal for browning and braising meats and vegetables. Self-basting spikes on the underside of the lid continuously return moisture to food.",
    price: 299.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0012/staub-cast-iron-braiser-d.jpg",
    ],
    category: "Cookware",
    specs: [
      "3.5-qt cast-iron braiser with self-basting lid spikes",
      "Matte black enamel interior develops natural nonstick seasoning over time",
      "Colorful exterior enamel in multiple finishes",
      "Oven safe to 500°F; induction compatible",
      "Made in France",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "mauviel-m-steel-carbon-skillet-12in",
    name: "Mauviel M'Steel Carbon Steel Skillet, 12\"",
    description:
      "Mauviel's carbon-steel skillet is a French restaurant staple. It heats fast, builds a natural nonstick seasoning, and is the choice of professional chefs worldwide.",
    price: 139.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0033/mauviel-m-steel-black-carbon-steel-skillet-d.jpg",
    ],
    category: "Cookware",
    specs: [
      "12\" carbon-steel skillet; lighter than cast iron, heats faster",
      "Develops natural nonstick patina with use and seasoning",
      "Works on all stovetops including induction",
      "Oven safe to 680°F",
      "Made in France",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },

  // ── COOKS' TOOLS ────────────────────────────
  {
    skuId: "ws-stainless-7pc-gadget-set",
    name: "Williams Sonoma Stainless-Steel 7-Piece Gadget Set",
    description:
      "Our stainless-steel gadget set gives you the essential tools for everyday cooking—all with ergonomic, soft-grip handles and dishwasher-safe construction.",
    price: 89.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0011/williams-sonoma-stainless-steel-gadget-set-d.jpg",
    ],
    category: "Cooks' Tools",
    specs: [
      "Set includes: ladle, slotted spoon, pasta fork, solid spoon, slotted spatula, whisk, and tongs",
      "18/10 stainless-steel construction",
      "Soft-grip ergonomic handles",
      "Dishwasher safe",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "oxo-good-grips-mandoline",
    name: "OXO Good Grips Chef's Mandoline Slicer",
    description:
      "This OXO mandoline makes precise, restaurant-quality cuts effortlessly. Dial in 30 thickness settings and switch between straight, julienne and waffle blades in seconds.",
    price: 99.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0055/oxo-good-grips-chefs-mandoline-slicer-d.jpg",
    ],
    category: "Cooks' Tools",
    specs: [
      "30 dial-adjustable thickness settings (0–9mm)",
      "Interchangeable straight, julienne and waffle blades",
      "Soft, nonslip hand guard for safety",
      "Folds flat for compact storage",
      "Dishwasher-safe blades and body",
    ],
    stars: 4.5,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "microplane-premium-classic-zester",
    name: "Microplane Premium Classic Zester/Grater",
    description:
      "The original Microplane zester uses razor-sharp, photo-etched stainless-steel blades to produce feather-light zest, grated cheese, and spice in seconds.",
    price: 17.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0080/microplane-premium-classic-zester-grater-d.jpg",
    ],
    category: "Cooks' Tools",
    specs: [
      "Photo-etched stainless-steel grating surface stays sharp longer",
      "Comfortable soft-grip handle with hanging loop",
      "Dishwasher safe",
      "Made in the USA",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-instant-read-thermometer",
    name: "Williams Sonoma Instant-Read Thermometer",
    description:
      "Get perfectly cooked meat every time with this instant-read thermometer. It delivers an accurate reading in just 2 seconds with a bright, easy-to-read rotating display.",
    price: 39.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0020/williams-sonoma-instant-read-thermometer-d.jpg",
    ],
    category: "Cooks' Tools",
    specs: [
      "2-second read time; ±0.9°F accuracy",
      "Rotating display readable at any angle",
      "Temperature range: -58°F to 572°F",
      "Auto-off after 10 minutes to preserve battery",
      "Splash-proof design; includes probe sheath",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-pro-kitchen-scale",
    name: "Williams Sonoma Escali Primo Digital Kitchen Scale",
    description:
      "Accurate baking starts with weight, not volume. This precision digital scale measures in grams, ounces, and pounds/ounces up to 11 lb with a tare function for seamless measuring.",
    price: 44.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0030/escali-primo-digital-kitchen-scale-d.jpg",
    ],
    category: "Cooks' Tools",
    specs: [
      "Capacity: 11 lb / 5 kg",
      "Measures in g, oz, and lb:oz",
      "Tare function zeros out weight of any bowl or container",
      "Large LCD display with backlight",
      "Auto-off; runs on 2 AA batteries (included)",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },

  // ── CUTLERY ─────────────────────────────────
  {
    skuId: "shun-classic-8in-chefs-knife",
    name: "Shun Classic Chef's Knife, 8\"",
    description:
      "Handcrafted in Seki, Japan, the Shun Classic is a revelation. The VG-MAX cutting core wrapped in 34 layers of Damascus stainless steel delivers extraordinary sharpness, edge retention, and beauty.",
    price: 169.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0050/shun-classic-chefs-knife-8-in-d.jpg",
    ],
    category: "Cutlery",
    specs: [
      "VG-MAX cutting core for exceptional sharpness and edge retention",
      "34 layers of high-carbon stainless Damascus cladding",
      "Ebony PakkaWood D-shaped handle for comfort and hygiene",
      "Hand-sharpened at 16° per side for razor precision",
      "Hand-wash recommended; made in Japan",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 0.8,
    arPlacementType: "tabletop",
  },
  {
    skuId: "wusthof-classic-7pc-block-set",
    name: "Wüsthof Classic 7-Piece Slim Knife Block Set",
    description:
      "Wüsthof Classic knives are forged from a single piece of high-carbon stainless steel in Solingen, Germany—renowned for their balance, weight, and durability across generations.",
    price: 549.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0040/wusthof-classic-7-piece-slim-knife-block-set-d.jpg",
    ],
    category: "Cutlery",
    specs: [
      "Includes: 3.5\" paring, 6\" utility, 8\" bread, 8\" chef's knives, kitchen shears, honing steel, and 13-slot acacia block",
      "Full-tang high-carbon stainless-steel blades forged in Solingen, Germany",
      "PEtec precision edge technology; hand-honed to 14° per side",
      "Triple-riveted synthetic handle provides comfort and balance",
      "Dishwasher safe (hand-wash recommended)",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.2,
    arPlacementType: "tabletop",
  },
  {
    skuId: "global-g2-8in-chefs-knife",
    name: "Global G-2 Chef's Knife, 8\"",
    description:
      "Crafted in Japan from CROMOVA 18 high-carbon stainless steel, the iconic Global G-2 is seamlessly constructed with its hollow handle filled with sand for perfect balance.",
    price: 129.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0061/global-g-2-chefs-knife-8-in-d.jpg",
    ],
    category: "Cutlery",
    specs: [
      "CROMOVA 18 stainless-steel blade holds an edge exceptionally well",
      "Seamless one-piece construction eliminates crevices where bacteria hide",
      "Hollow handle filled with sand provides ideal balance",
      "Dimple pattern on handle offers a secure grip",
      "Hand-wash recommended; made in Japan",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.8,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-pro-honing-steel-12in",
    name: "Williams Sonoma Honing Steel, 12\"",
    description:
      "Keep your knives performing at their peak with this professional honing steel. Regular honing realigns the blade's edge between sharpenings, extending the life of your knives.",
    price: 49.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0045/williams-sonoma-honing-steel-d.jpg",
    ],
    category: "Cutlery",
    specs: [
      "12\" chrome-plated steel rod",
      "Medium-grit texture for regular maintenance",
      "Ergonomic handle with finger guard",
      "Hanging loop for easy storage",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },

  // ── ELECTRICS ───────────────────────────────
  {
    skuId: "breville-barista-express-espresso",
    name: "Breville Barista Express Espresso Machine",
    description:
      "From bean to espresso in under a minute. The Barista Express integrates a conical burr grinder directly into the machine and offers full digital temperature control for third-wave-quality shots at home.",
    price: 749.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0011/breville-barista-express-espresso-machine-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "Integrated conical burr grinder with 25 settings",
      "Digital temperature control (PID) for precise extraction",
      "15-bar Italian pump for professional pressure",
      "Steam wand creates micro-foam milk for latte art",
      "67 oz removable water tank",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.2,
    arPlacementType: "tabletop",
  },
  {
    skuId: "kitchenaid-artisan-stand-mixer-5qt",
    name: "KitchenAid Artisan Series 5-Qt. Stand Mixer",
    description:
      "The iconic KitchenAid Artisan stand mixer has been a kitchen staple for decades. Its 325-watt motor and planetary mixing action reach every part of the bowl for thorough mixing every time.",
    price: 449.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0021/kitchenaid-artisan-series-5-qt-stand-mixer-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "5-qt stainless-steel mixing bowl",
      "325-watt motor with 10-speed control",
      "Planetary mixing action for thorough bowl coverage",
      "Includes: flat beater, dough hook, wire whip, and pouring shield",
      "Power hub accepts 15+ optional attachments",
      "Available in 20+ colors",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.1,
    arPlacementType: "tabletop",
  },
  {
    skuId: "vitamix-a3500-ascent-blender",
    name: "Vitamix A3500 Ascent Series Smart Blender",
    description:
      "The Vitamix A3500 brings professional-grade blending home with five pre-programmed settings, wireless connectivity with the Vitamix Perfect Blend app, and a self-cleaning cycle.",
    price: 599.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0015/vitamix-a3500-ascent-series-smart-blender-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "2.2-peak-HP motor blends ice, frozen fruit, and nut butters effortlessly",
      "Five pre-programmed settings: smoothie, hot soup, dip/spread, frozen dessert, self-clean",
      "Variable speed control + pulse feature",
      "Wireless connectivity with Perfect Blend app",
      "64 oz low-profile container; dishwasher safe",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.1,
    arPlacementType: "tabletop",
  },
  {
    skuId: "cuisinart-food-processor-14cup",
    name: "Cuisinart Custom 14-Cup Food Processor",
    description:
      "The Cuisinart Custom 14 handles every prep task imaginable—slicing, shredding, chopping, pureeing—quickly and quietly with its powerful 720-watt motor.",
    price: 249.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0035/cuisinart-custom-14-cup-food-processor-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "14-cup capacity work bowl with handle",
      "720-watt motor; 2-speed + pulse control",
      "Includes: chopping blade, medium slicing disc, medium shredding disc, dough blade",
      "SealTight advantage system prevents leaks",
      "Dishwasher-safe bowl, lid, and blades",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 1.1,
    arPlacementType: "tabletop",
  },
  {
    skuId: "breville-smart-oven-air-fryer-pro",
    name: "Breville Smart Oven Air Fryer Pro",
    description:
      "13 versatile cooking functions—air fry, roast, broil, bake, dehydrate, and more—make this Breville countertop oven the most capable appliance in your kitchen.",
    price: 399.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0008/breville-smart-oven-air-fryer-pro-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "13 cooking functions including Air Fry, Dehydrate, Proof, and Pizza",
      "Element IQ system directs power exactly where needed",
      "Large capacity fits a 13\" pizza or 9 x 13\" baking pan",
      "Interior light and non-stick easy-clean enamel lining",
      "Includes: air fry basket, broil rack, baking pan, and oven mitt",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.3,
    arPlacementType: "tabletop",
  },
  {
    skuId: "nespresso-vertuo-next-coffee-maker",
    name: "Nespresso Vertuo Next Coffee & Espresso Machine",
    description:
      "Brew café-quality coffee and espresso at the push of a button. Nespresso's Centrifusion technology reads each pod's barcode to automatically optimize brewing parameters.",
    price: 179.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0070/nespresso-vertuo-next-coffee-maker-d.jpg",
    ],
    category: "Electrics",
    specs: [
      "Centrifusion extraction technology for a rich, full-flavored cup",
      "Brews five cup sizes: espresso (1.35 oz) to alto XL (14 oz)",
      "Barcode recognition automatically sets brew parameters per pod",
      "37 oz water tank; 13-pod used capsule container",
      "Heats up in 25 seconds; auto-off after 9 minutes",
    ],
    stars: 4.5,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },

  // ── BAKEWARE ────────────────────────────────
  {
    skuId: "nordic-ware-half-sheet-pan-2pk",
    name: "Nordic Ware Naturals Half Sheet Pans, Set of 2",
    description:
      "A cult-favorite among serious bakers, Nordic Ware's natural aluminum sheet pans heat evenly and won't warp, rust, or react with acidic foods.",
    price: 34.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0090/nordic-ware-naturals-half-sheet-pans-set-of-2-d.jpg",
    ],
    category: "Bakeware",
    specs: [
      "Set of 2 half sheet pans (18 x 13\")",
      "Natural aluminum for even, warp-free heating",
      "Reinforced encapsulated steel rim prevents warping",
      "Commercial grade; made in the USA",
      "Hand-wash recommended",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 1.2,
    arPlacementType: "tabletop",
  },
  {
    skuId: "williams-sonoma-goldtouch-9x13-pan",
    name: "Williams Sonoma Goldtouch® Pro Nonstick Rectangular Cake Pan, 9\" x 13\"",
    description:
      "Our Goldtouch Pro pan features a gold-toned nonstick coating that releases baked goods flawlessly and cleans up in seconds—the go-to pan for brownies, sheet cakes, and casseroles.",
    price: 54.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0055/williams-sonoma-goldtouch-pro-nonstick-rectangular-cake-pan-d.jpg",
    ],
    category: "Bakeware",
    specs: [
      "9 x 13\" rectangular cake pan",
      "Gold-toned nonstick interior for effortless food release",
      "Aluminized steel construction for even browning",
      "Dishwasher safe; oven safe to 450°F",
      "Made in the USA",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "emile-henry-pie-dish-9in",
    name: "Emile Henry 9\" Pie Dish",
    description:
      "Emile Henry's Burgundian clay pie dish bakes crusts to a beautiful golden brown while retaining heat to keep pies warm at the table.",
    price: 44.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0100/emile-henry-9-pie-dish-d.jpg",
    ],
    category: "Bakeware",
    specs: [
      "9\" diameter; 1.5\" deep",
      "High-fired Burgundian clay for even heat distribution",
      "Glazed surface resists staining and is easy to clean",
      "Oven safe to 520°F; microwave, freezer, and dishwasher safe",
      "Made in France",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.9,
    arPlacementType: "tabletop",
  },
  {
    skuId: "chicago-metallic-muffin-pan-12cup",
    name: "Chicago Metallic Professional Nonstick 12-Cup Muffin Pan",
    description:
      "Bake a perfect batch of muffins every time with Chicago Metallic's commercial-grade steel pan with Americoat nonstick coating that's PTFE and PFOA-free.",
    price: 29.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0110/chicago-metallic-professional-nonstick-12-cup-muffin-pan-d.jpg",
    ],
    category: "Bakeware",
    specs: [
      "12-cup standard muffin pan",
      "Americoat PTFE/PFOA-free nonstick coating",
      "Aluminized steel for even, consistent baking",
      "Dishwasher safe; oven safe to 450°F",
      "Made in the USA",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },

  // ── FOOD ────────────────────────────────────
  {
    skuId: "ws-peppercorn-medley-grinder",
    name: "Williams Sonoma Peppercorn Medley with Grinder",
    description:
      "A vibrant mix of black, white, pink, green, and allspice berries with an adjustable ceramic grinder for fresh, fragrant pepper on every dish.",
    price: 14.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0120/williams-sonoma-peppercorn-medley-with-grinder-d.jpg",
    ],
    category: "Food",
    specs: [
      "Blend of black, white, pink, green, and allspice berries",
      "Adjustable ceramic grinder built into the jar",
      "3 oz jar; no additives or preservatives",
      "Refillable grinder",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 0.5,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-hot-cocoa-mix-classic",
    name: "Williams Sonoma Classic Hot Cocoa Mix",
    description:
      "Made with premium Dutch-process cocoa, our signature hot cocoa mix is a Williams-Sonoma tradition—rich, chocolatey, and perfectly balanced.",
    price: 19.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0130/williams-sonoma-classic-hot-cocoa-mix-d.jpg",
    ],
    category: "Food",
    specs: [
      "13 oz canister; makes approximately 13 servings",
      "Premium Dutch-process cocoa; no artificial flavors",
      "Mix with milk or water",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 0.5,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-calabrian-chili-oil",
    name: "Williams Sonoma Calabrian Chili Oil",
    description:
      "Drizzle this bold, vibrant oil over pizza, pasta, eggs, and grilled meats. Made from Calabrian chilis grown in southern Italy and cold-pressed extra-virgin olive oil.",
    price: 16.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0070/williams-sonoma-calabrian-chili-oil-d.jpg",
    ],
    category: "Food",
    specs: [
      "8.5 fl oz bottle",
      "Calabrian chilis in extra-virgin olive oil",
      "No artificial preservatives; imported from Italy",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.5,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-vanilla-bean-paste",
    name: "Williams Sonoma Pure Vanilla Bean Paste",
    description:
      "See the bean! Our pure vanilla bean paste has the rich flavor and beautiful specks of real vanilla beans—perfect for custards, ice cream, and buttercream.",
    price: 21.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202501/0080/williams-sonoma-pure-vanilla-bean-paste-d.jpg",
    ],
    category: "Food",
    specs: [
      "4 oz jar; 1 tsp equals 1 vanilla bean",
      "Made with real vanilla bean seeds",
      "No artificial flavors; gluten-free",
    ],
    stars: 4.9,
    reviews: [],
    arModelUrl: null,
    arScale: 0.4,
    arPlacementType: "tabletop",
  },

  // ── TABLETOP & BAR ──────────────────────────
  {
    skuId: "riedel-performance-cabernet-2pk",
    name: "Riedel Performance Cabernet/Merlot Wine Glasses, Set of 2",
    description:
      "Riedel's Performance series features a unique optical lens at the base of the bowl, designed to aerate and direct wine to the optimal area of the palate for each varietal.",
    price: 79.90,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0140/riedel-performance-cabernet-merlot-wine-glasses-set-of-2-d.jpg",
    ],
    category: "Tabletop & Bar",
    specs: [
      "Set of 2 lead-free crystal Cabernet/Merlot glasses",
      "Optical lens at base aerates and enhances the wine's bouquet",
      "Machine-made for consistent precision",
      "Dishwasher safe",
      "Made in Germany",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 0.7,
    arPlacementType: "tabletop",
  },
  {
    skuId: "open-kitchen-marble-cheese-board",
    name: "Williams Sonoma Marble Cheese Board with Handles",
    description:
      "Entertain in style with this gorgeous white Carrara marble board. Its natural cool surface keeps cheeses and charcuterie fresh, and the integrated handles make it easy to carry.",
    price: 89.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0080/williams-sonoma-marble-cheese-board-with-handles-d.jpg",
    ],
    category: "Tabletop & Bar",
    specs: [
      "16\" x 8\" genuine Carrara marble surface",
      "Stainless-steel integrated handles",
      "Natural cool surface ideal for cheese and charcuterie",
      "Includes 4 stainless-steel cheese markers",
      "Hand-wash only",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "cocktail-kingdom-bar-tool-set-5pc",
    name: "Cocktail Kingdom 5-Piece Bar Tool Set",
    description:
      "Craft professional cocktails at home with this sleek set of essential bar tools. Each piece is weighted for balance and made from polished stainless steel.",
    price: 124.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0090/cocktail-kingdom-5-piece-bar-tool-set-d.jpg",
    ],
    category: "Tabletop & Bar",
    specs: [
      "Set includes: mixing glass, bar spoon, julep strainer, Hawthorne strainer, and jigger",
      "Polished stainless-steel construction",
      "24 oz mixing glass holds enough for two cocktails",
      "Weighted for professional balance",
      "Hand-wash recommended",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.8,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-hammered-copper-moscow-mule-mugs-2pk",
    name: "Williams Sonoma Hammered Copper Moscow Mule Mugs, Set of 2",
    description:
      "Serve Moscow mules the classic way—in a chilled copper mug. The naturally cold-conducting copper keeps cocktails icy cold from the first sip to the last.",
    price: 49.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0150/williams-sonoma-hammered-copper-moscow-mule-mugs-set-of-2-d.jpg",
    ],
    category: "Tabletop & Bar",
    specs: [
      "Set of 2; 16 oz capacity each",
      "Pure copper exterior with nickel-lined interior",
      "Hammered texture for an artisanal look",
      "Handle riveted for durability",
      "Hand-wash only",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.6,
    arPlacementType: "tabletop",
  },

  // ── HOME ESSENTIALS ─────────────────────────
  {
    skuId: "simplehuman-sensor-soap-pump-9oz",
    name: "Simplehuman Touch-Free Sensor Soap Pump, 9 oz.",
    description:
      "Simplehuman's sensor pump dispenses the right amount of soap every time—no touching the pump, no mess. Works with any liquid hand soap or dish soap.",
    price: 49.99,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0160/simplehuman-touch-free-sensor-soap-pump-d.jpg",
    ],
    category: "Home Essentials",
    specs: [
      "9 oz capacity; works with any liquid hand or dish soap",
      "Infrared sensor dispenses hands-free",
      "Adjustable volume control (low, medium, high)",
      "Weighted rubber base prevents tipping",
      "Powered by 4 AA batteries (included)",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 0.5,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-weck-canning-jar-set-6pc",
    name: "Weck Tulip Jar Set, Set of 6",
    description:
      "German-made Weck jars are the beautiful, eco-friendly alternative to plastic storage. Their glass lids and rubber gaskets create an airtight seal for preserves, pantry staples, and leftovers.",
    price: 39.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0170/weck-tulip-jar-set-set-of-6-d.jpg",
    ],
    category: "Home Essentials",
    specs: [
      "Set of 6 tulip jars, 1⁄4 liter (8.5 oz) each",
      "Borosilicate glass body with glass lid and orange rubber gasket",
      "Includes stainless-steel clips for sealing",
      "Dishwasher, freezer, and microwave safe",
      "Made in Germany since 1900",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.5,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-linen-apron-natural",
    name: "Williams Sonoma Classic Stripe Linen Apron",
    description:
      "Look as good as your food. Our classic linen apron has a generous bib, two front pockets, and adjustable neck strap—everything a home cook needs.",
    price: 64.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0100/williams-sonoma-classic-stripe-linen-apron-d.jpg",
    ],
    category: "Home Essentials",
    specs: [
      "100% washed linen; softens with each wash",
      "Adjustable neck strap; long waist ties wrap and tie in front",
      "Two front pockets",
      "Machine washable",
      "One size fits most",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "floor",
  },

  // ── OUTDOOR & GARDEN ─────────────────────────
  {
    skuId: "weber-spirit-ii-e310-gas-grill",
    name: "Weber Spirit II E-310 3-Burner Gas Grill",
    description:
      "Weber's Spirit II E-310 packs 30,000 BTUs into three stainless-steel burners over 529 sq in of cooking area—enough to cook a meal for any gathering.",
    price: 649.00,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0060/weber-spirit-ii-e-310-3-burner-gas-grill-d.jpg",
    ],
    category: "Outdoor & Garden",
    specs: [
      "3 stainless-steel burners; 30,000 BTU-per-hour input",
      "529 sq in primary cooking area + 105 sq in warming rack",
      "GS4 grilling system: porcelain-enameled Flavorizer bars, infinity ignition",
      "Open cart design with two side tables and hooks",
      "10-year warranty on burners, cooking grates, and porcelain-coated lid",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 2.0,
    arPlacementType: "floor",
  },
  {
    skuId: "traeger-ironwood-xl-pellet-grill",
    name: "Traeger Ironwood XL Pellet Grill",
    description:
      "The Traeger Ironwood XL brings the full wood-fired experience to your backyard. Wi-Fi connectivity, a full-color touchscreen, and 924 sq in of cooking space put you in control of every cook.",
    price: 1799.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0065/traeger-ironwood-xl-pellet-grill-d.jpg",
    ],
    category: "Outdoor & Garden",
    specs: [
      "924 sq in total grilling area",
      "Wi-Fi + Bluetooth connectivity via the Traeger app",
      "Full-color touchscreen with pop-and-lock accessories rail",
      "Super Smoke mode for maximum smoke flavor",
      "Temperature range: 165°F–500°F; ±5°F accuracy",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 2.5,
    arPlacementType: "floor",
  },
  {
    skuId: "lodge-cast-iron-grill-pan-10.5in",
    name: "Lodge Cast Iron Square Grill Pan, 10.5\"",
    description:
      "Bring the grill indoors. Lodge's seasoned cast-iron grill pan creates authentic grill marks and incredible char on steaks, chicken, and vegetables on any stovetop.",
    price: 39.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0180/lodge-cast-iron-square-grill-pan-d.jpg",
    ],
    category: "Outdoor & Garden",
    specs: [
      "10.5\" square grill pan with raised ridges",
      "Pre-seasoned with 100% natural vegetable oil",
      "Works on all cooking surfaces including induction",
      "Oven safe to any temperature",
      "Made in the USA",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 0.9,
    arPlacementType: "tabletop",
  },

  // ── FURNITURE ───────────────────────────────
  {
    skuId: "ws-butcher-block-kitchen-island",
    name: "Williams Sonoma Classic Butcher-Block Kitchen Island",
    description:
      "Add prep space and storage with our solid hardwood butcher-block island. Durable maple top, deep drawers, and a lower shelf keep everything within easy reach.",
    price: 1299.00,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0080/williams-sonoma-classic-butcher-block-kitchen-island-d.jpg",
    ],
    category: "Furniture",
    specs: [
      "Solid maple butcher-block top; 36\" counter height",
      "Two deep drawers with stainless-steel hardware",
      "Lower shelf for storage; locking casters for mobility",
      "Dimensions: 48\"W x 24\"D x 36\"H",
      "Finish: natural maple top with white base",
    ],
    stars: 4.5,
    reviews: [],
    arModelUrl: null,
    arScale: 3.0,
    arPlacementType: "floor",
  },
  {
    skuId: "ws-bakers-rack-steel",
    name: "Williams Sonoma Industrial Baker's Rack",
    description:
      "Our industrial baker's rack combines open shelving for cookware and appliances with a wine rack, hooks, and a sturdy steel frame—a stylish solution for organized kitchens.",
    price: 499.00,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0085/williams-sonoma-industrial-bakers-rack-d.jpg",
    ],
    category: "Furniture",
    specs: [
      "Steel frame with antique bronze finish",
      "4 open shelves + built-in wine rack for 8 bottles",
      "Hanging rod with 6 S-hooks for pots and pans",
      "Dimensions: 36\"W x 16\"D x 72\"H",
      "Assembly required",
    ],
    stars: 4.4,
    reviews: [],
    arModelUrl: null,
    arScale: 3.5,
    arPlacementType: "floor",
  },

  // ── GIFTS ───────────────────────────────────
  {
    skuId: "ws-ultimate-baking-gift-box",
    name: "Williams Sonoma Ultimate Baking Gift Set",
    description:
      "Everything a home baker needs in one gorgeous gift box: premium vanilla, specialty sugars, Dutch-process cocoa, and our exclusive Goldtouch mini loaf pans.",
    price: 89.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0200/williams-sonoma-ultimate-baking-gift-set-d.jpg",
    ],
    category: "Gifts",
    specs: [
      "Includes: pure vanilla bean paste, turbinado sugar, Dutch-process cocoa, fleur de sel, and set of 4 Goldtouch mini loaf pans",
      "Arrives in a Williams-Sonoma gift box with ribbon",
      "Ready to give—no additional wrapping needed",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-global-grilling-spice-set",
    name: "Williams Sonoma Global Grilling Spice Rub Collection, Set of 6",
    description:
      "Take your grill around the world with six expertly blended spice rubs—from smoky Kansas City BBQ to aromatic Moroccan chermoula and Japanese miso tare.",
    price: 59.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202502/0110/williams-sonoma-global-grilling-spice-rub-collection-d.jpg",
    ],
    category: "Gifts",
    specs: [
      "Set of 6 spice rub jars: Kansas City BBQ, Moroccan Chermoula, Japanese Miso, Tuscan Herb, Tex-Mex, and Peruvian Ají",
      "2 oz per jar; no artificial flavors or preservatives",
      "Packaged in a gift-ready box",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.7,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-handcrafted-pasta-making-kit",
    name: "Williams Sonoma Pasta Making Kit",
    description:
      "Everything you need to craft fresh pasta from scratch: a classic Atlas pasta machine, semolina flour, and our complete fresh pasta cookbook.",
    price: 119.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0090/williams-sonoma-pasta-making-kit-d.jpg",
    ],
    category: "Gifts",
    specs: [
      "Includes: Marcato Atlas 150 pasta machine, 2 lb semolina flour, and Williams-Sonoma Fresh Pasta cookbook",
      "Machine makes pasta sheets and cuts fettuccine and tagliolini",
      "10 adjustable thickness settings",
      "Clamps to countertop; chrome-plated steel construction",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.1,
    arPlacementType: "tabletop",
  },

  // ── HOLIDAYS ────────────────────────────────
  {
    skuId: "ws-nordic-ware-holiday-bundt-pan",
    name: "Nordic Ware Platinum Snowflake Bundt Pan",
    description:
      "Bake showstopping holiday cakes in this intricate snowflake-patterned Bundt pan. Cast aluminum construction ensures every delicate detail releases perfectly.",
    price: 39.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0210/nordic-ware-platinum-snowflake-bundt-pan-d.jpg",
    ],
    category: "Holidays",
    specs: [
      "10-cup capacity; 10\" diameter",
      "Cast aluminum with premium nonstick coating",
      "Intricate snowflake design releases cleanly every time",
      "Oven safe to 400°F",
      "Made in the USA",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 0.9,
    arPlacementType: "tabletop",
  },
  {
    skuId: "ws-gingerbread-house-kit",
    name: "Williams Sonoma Gingerbread House Kit",
    description:
      "Build and decorate a bakery-worthy gingerbread house with our all-inclusive kit—pre-baked walls, colorful candy decorations, royal icing mix, and a decorating bag included.",
    price: 44.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0220/williams-sonoma-gingerbread-house-kit-d.jpg",
    ],
    category: "Holidays",
    specs: [
      "Pre-baked gingerbread house panels; no baking required",
      "Royal icing mix + 3 decorating bags and tips",
      "Assorted candy decorations included",
      "Assembles to approximately 9\"H x 7\"W",
    ],
    stars: 4.6,
    reviews: [],
    arModelUrl: null,
    arScale: 0.8,
    arPlacementType: "tabletop",
  },

  // ── NEW ─────────────────────────────────────
  {
    skuId: "hestan-nanobond-skillet-12in",
    name: "Hestan NanoBond Titanium Skillet, 12\"",
    description:
      "Hestan's NanoBond technology bonds thousands of titanium layers onto surgical-grade stainless steel, creating the hardest, most durable cooking surface ever made—4x harder than stainless and metal-utensil safe.",
    price: 249.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0100/hestan-nanobond-titanium-skillet-12-in-d.jpg",
    ],
    category: "New",
    specs: [
      "NanoBond titanium surface: 4x harder than stainless steel",
      "Metal-utensil safe; won't scratch or chip",
      "Highest heat tolerance of any cookware: oven safe to 1050°F",
      "Induction compatible; dishwasher safe",
      "Made in Italy",
    ],
    stars: 4.8,
    reviews: [],
    arModelUrl: null,
    arScale: 1.0,
    arPlacementType: "tabletop",
  },
  {
    skuId: "wolf-gourmet-precision-griddle",
    name: "Wolf Gourmet Precision Electric Griddle",
    description:
      "The Wolf Gourmet electric griddle delivers professional restaurant-level temperature control across its entire 21\" x 12\" cooking surface—perfect for pancakes, smash burgers, and Sunday brunches.",
    price: 399.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0105/wolf-gourmet-precision-electric-griddle-d.jpg",
    ],
    category: "New",
    specs: [
      "21\" x 12\" non-stick cooking surface",
      "Precise temperature control from 200°F to 450°F",
      "Even heat from edge to edge with no hot spots",
      "Removable grease tray; dishwasher-safe surface",
      "Includes splatter shield",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 1.3,
    arPlacementType: "tabletop",
  },

  // ── SALE ────────────────────────────────────
  {
    skuId: "all-clad-ha1-nonstick-fry-pan-10in-sale",
    name: "All-Clad HA1 Hard Anodized Nonstick Fry Pan, 10\"",
    description:
      "All-Clad's hard-anodized nonstick fry pan is a kitchen workhorse for everyday cooking. PFOA-free 3-layer nonstick coating, stay-cool handle, and dishwasher-safe construction.",
    price: 79.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202503/0110/all-clad-ha1-hard-anodized-nonstick-fry-pan-d.jpg",
    ],
    category: "Sale",
    specs: [
      "10\" hard-anodized aluminum fry pan",
      "3-layer PFOA-free nonstick coating",
      "Stay-cool stainless-steel handle",
      "Dishwasher safe; oven safe to 500°F",
      "Was $129.95",
    ],
    stars: 4.7,
    reviews: [],
    arModelUrl: null,
    arScale: 0.9,
    arPlacementType: "tabletop",
  },
  {
    skuId: "cuisinart-ice-cream-maker-sale",
    name: "Cuisinart Automatic Ice Cream Maker, 1.5 Qt.",
    description:
      "Make fresh, creamy ice cream, frozen yogurt, and sorbet at home in as little as 20 minutes—no rock salt, no ice. Just add your mixture and press start.",
    price: 59.95,
    images: [
      "https://assets.wsimgs.com/wsimgs/rk/images/dp/wcm/202412/0240/cuisinart-automatic-ice-cream-maker-d.jpg",
    ],
    category: "Sale",
    specs: [
      "1.5 qt. double-insulated freezer bowl",
      "20–25 minute freeze time",
      "Ingredients added through large spout while running",
      "BPA-free; dishwasher-safe lid and paddle",
      "Was $99.95",
    ],
    stars: 4.5,
    reviews: [],
    arModelUrl: null,
    arScale: 0.9,
    arPlacementType: "tabletop",
  },
];

// ─────────────────────────────────────────────
// Seeding function
// ─────────────────────────────────────────────
async function seedProducts() {
  try {
    console.log("Connecting to MongoDB...");
    await mongoose.connect(process.env.MONGO_URI);
    console.log("✅ Connected!");

    console.log("Clearing existing products to prevent duplicates...");
    await Product.deleteMany({});

    // ── Merge skus.json products (if the file exists) ──────────
    let extraProducts = [];
    const skusPath = path.join(__dirname, "responses", "skus.json");

    if (fs.existsSync(skusPath)) {
      console.log("Found skus.json – merging existing SKUs...");
      const rawSkus = JSON.parse(fs.readFileSync(skusPath, "utf8"));

      const CATEGORIES = [
        "New", "Cookware", "Cooks' Tools", "Cutlery", "Electrics",
        "Bakeware", "Food", "Tabletop & Bar", "Home Essentials",
        "Outdoor & Garden", "Furniture", "Holidays", "Gifts", "Sale",
      ];
      const getRandom = (arr) => arr[Math.floor(Math.random() * arr.length)];
      const getRandomStars = () =>
        parseFloat((Math.random() * (5.0 - 3.5) + 3.5).toFixed(1));

      // Avoid duplicate skuIds with the curated list
      const curatedIds = new Set(WS_PRODUCTS.map((p) => p.skuId));

      extraProducts = rawSkus
        .filter((sku) => !curatedIds.has(sku.id))
        .map((sku) => ({
          skuId: sku.id,
          name: sku.name,
          description:
            sku.properties?.shortName ||
            "Premium Williams Sonoma quality product.",
          price: sku.price?.sellingPrice || 50.0,
          images: sku.media?.images?.map((img) => img.path) || [],
          category: getRandom(CATEGORIES),
          specs: [
            "High-quality material",
            "Exclusive to Williams Sonoma",
            "Dishwasher safe",
          ],
          stars: getRandomStars(),
          reviews: [],
          arModelUrl: null,
          arScale: 1.0,
          arPlacementType: "tabletop",
        }));

      console.log(`  → ${extraProducts.length} products from skus.json added.`);
    } else {
      console.log("No skus.json found – skipping SKU merge.");
    }

    const productsToInsert = [...WS_PRODUCTS, ...extraProducts].map((product) => ({
      ...product,
      images: localImagesForProduct(product),
    }));

    console.log(
      `Preparing to insert ${productsToInsert.length} products (${WS_PRODUCTS.length} curated + ${extraProducts.length} from skus.json)...`
    );

    await Product.insertMany(productsToInsert);

    console.log("✅ Successfully seeded the database!");
    process.exit(0);
  } catch (error) {
    console.error("❌ Error seeding the database:", error);
    process.exit(1);
  }
}

seedProducts();
