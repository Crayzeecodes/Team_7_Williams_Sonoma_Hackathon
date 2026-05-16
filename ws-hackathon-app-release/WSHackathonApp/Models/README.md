# USDZ 3D Models

Place your `.usdz` files in this folder, then drag this folder into the Xcode project.

## How to add USDZ files to Xcode:

1. **Download free USDZ models** from:
   - [Apple AR Quick Look Gallery](https://developer.apple.com/augmented-reality/quick-look/)
   - [Sketchfab](https://sketchfab.com/) (filter by USDZ format)
   - [TurboSquid](https://www.turbosquid.com/) (search for free USDZ)

2. **Place the .usdz files** in this `Models/` folder

3. **Add to Xcode project:**
   - Open the project in Xcode
   - Right-click on the project navigator (left sidebar)
   - Select **"Add Files to WSHackathonApp..."**
   - Navigate to this `Models/` folder
   - Select all `.usdz` files
   - ✅ Check **"Copy items if needed"**
   - ✅ Check **"Create folder references"** (or "Create groups")
   - ✅ Make sure **"WSHackathonApp"** target is checked
   - Click **Add**

4. **Update the model mapping** in `ARViewerViewModel.swift`:
   ```swift
   private static let usdzModelMap: [String: String] = [
       "Cookware": "your_pot_model",        // filename without .usdz
       "Electrics": "your_mixer_model",
       "Tabletop & Bar": "your_board_model",
   ]
   ```

5. **Verify:** Build the project (⌘B). If the USDZ files are properly added, 
   `Bundle.main.url(forResource:withExtension:"usdz")` will find them.

## Without USDZ files
The app works fine without any USDZ files — it automatically creates 
colored 3D box models as placeholders for the AR demo.
