"""
Generate detailed recommendations for achieving 85%+ accuracy
Shows exactly how many more images needed per category
"""

import os
from pathlib import Path

def analyze_for_high_accuracy(dataset_path):
    """Analyze dataset and provide specific recommendations for 85%+ accuracy"""
    
    train_path = Path(dataset_path) / 'train'
    
    if not train_path.exists():
        print("❌ Training dataset not found!")
        return
    
    print("=" * 90)
    print("🎯 TARGET: 85%+ VALIDATION ACCURACY")
    print("=" * 90)
    
    # Count images per category
    category_stats = {}
    
    for category_folder in sorted(train_path.iterdir()):
        if not category_folder.is_dir():
            continue
        
        images = [
            f for f in category_folder.iterdir()
            if f.is_file() and f.suffix.lower() in ['.jpg', '.jpeg', '.png']
        ]
        
        category_stats[category_folder.name] = len(images)
    
    # Calculate statistics
    total_categories = len(category_stats)
    total_images = sum(category_stats.values())
    
    # Targets for 85%+ accuracy
    TARGET_MIN = 150  # Minimum per category
    TARGET_IDEAL = 250  # Ideal per category
    
    # Categorize
    critical = {k: v for k, v in category_stats.items() if v < 100}
    needs_more = {k: v for k, v in category_stats.items() if 100 <= v < TARGET_MIN}
    acceptable = {k: v for k, v in category_stats.items() if TARGET_MIN <= v < TARGET_IDEAL}
    excellent = {k: v for k, v in category_stats.items() if v >= TARGET_IDEAL}
    
    print(f"\n📊 Current Dataset Status:")
    print(f"   Total Categories: {total_categories}")
    print(f"   Total Training Images: {total_images:,}")
    print(f"   Average per Category: {total_images/total_categories:.1f}")
    
    print(f"\n📈 Category Quality Breakdown:")
    print(f"   🔴 Critical (<100 images):     {len(critical):3d} categories ({len(critical)/total_categories*100:.1f}%)")
    print(f"   🟡 Needs More (100-149):       {len(needs_more):3d} categories ({len(needs_more)/total_categories*100:.1f}%)")
    print(f"   🟢 Acceptable (150-249):       {len(acceptable):3d} categories ({len(acceptable)/total_categories*100:.1f}%)")
    print(f"   ✅ Excellent (250+):            {len(excellent):3d} categories ({len(excellent)/total_categories*100:.1f}%)")
    
    # Calculate total images needed
    total_needed = 0
    for cat, count in category_stats.items():
        if count < TARGET_MIN:
            total_needed += (TARGET_MIN - count)
    
    total_ideal = 0
    for cat, count in category_stats.items():
        if count < TARGET_IDEAL:
            total_ideal += (TARGET_IDEAL - count)
    
    print("\n" + "=" * 90)
    print("📋 RECOMMENDATION TIERS")
    print("=" * 90)
    
    print(f"\n🎯 TIER 1: MINIMUM for 85% Accuracy (150 images/category)")
    print(f"   Need to collect: {total_needed:,} more images")
    print(f"   Affects: {len(critical) + len(needs_more)} categories")
    print(f"   Expected result: ~85% validation accuracy")
    
    print(f"\n🌟 TIER 2: IDEAL for 90%+ Accuracy (250 images/category)")
    print(f"   Need to collect: {total_ideal:,} more images")
    print(f"   Affects: {len(critical) + len(needs_more) + len(acceptable)} categories")
    print(f"   Expected result: ~90%+ validation accuracy")
    
    # Priority list
    print("\n" + "=" * 90)
    print("🚨 PRIORITY ACTION LIST - What to Collect NOW")
    print("=" * 90)
    
    # Sort by need (fewest images first = highest priority)
    sorted_by_need = sorted(category_stats.items(), key=lambda x: x[1])
    
    print(f"\n🔴 CRITICAL PRIORITY (Need 50+ more images each):")
    print(f"   These {len(critical)} categories will drag down accuracy the most!\n")
    
    critical_count = 0
    for cat, count in sorted_by_need:
        if count < 100:
            needed_min = TARGET_MIN - count
            needed_ideal = TARGET_IDEAL - count
            print(f"   {critical_count+1:2d}. {cat:35s} - Current: {count:3d} → Need: {needed_min:3d} more (Ideal: {needed_ideal:3d})")
            critical_count += 1
    
    print(f"\n🟡 HIGH PRIORITY (Need 20-50 more images each):")
    print(f"   These {len(needs_more)} categories need a boost:\n")
    
    high_priority_count = 0
    for cat, count in sorted_by_need:
        if 100 <= count < TARGET_MIN:
            needed_min = TARGET_MIN - count
            needed_ideal = TARGET_IDEAL - count
            print(f"   {high_priority_count+1:2d}. {cat:35s} - Current: {count:3d} → Need: {needed_min:3d} more (Ideal: {needed_ideal:3d})")
            high_priority_count += 1
            if high_priority_count >= 20:  # Limit display
                remaining = len(needs_more) - 20
                if remaining > 0:
                    print(f"   ... and {remaining} more categories")
                break
    
    print(f"\n🟢 OPTIONAL (Already acceptable, but more helps):")
    print(f"   These {len(acceptable)} categories are OK but could be better:\n")
    
    opt_count = 0
    for cat, count in sorted(acceptable.items(), key=lambda x: x[1]):
        needed_ideal = TARGET_IDEAL - count
        print(f"   {opt_count+1:2d}. {cat:35s} - Current: {count:3d} → Ideal: +{needed_ideal:3d} more")
        opt_count += 1
        if opt_count >= 10:
            remaining = len(acceptable) - 10
            if remaining > 0:
                print(f"   ... and {remaining} more categories")
            break
    
    print(f"\n✅ NO ACTION NEEDED:")
    print(f"   These {len(excellent)} categories already have plenty of data!")
    
    # Execution plan
    print("\n" + "=" * 90)
    print("📝 EXECUTION PLAN - How to Collect Images")
    print("=" * 90)
    
    print("\n🎯 OPTION 1: Minimum Viable (Target 85% accuracy)")
    print(f"   Total images to collect: ~{total_needed:,}")
    print(f"   Categories to focus on: {len(critical) + len(needs_more)}")
    print(f"   Time estimate: 2-4 days (if sourcing from web)")
    print(f"   Strategy:")
    print(f"   1. Start with {len(critical)} CRITICAL categories (highest impact)")
    print(f"   2. Collect 50-80 images each from Kaggle/Google Images")
    print(f"   3. Then tackle HIGH PRIORITY categories")
    print(f"   4. Stop when all categories have 150+ images")
    
    print("\n🌟 OPTION 2: Optimal (Target 90%+ accuracy)")
    print(f"   Total images to collect: ~{total_ideal:,}")
    print(f"   Categories to focus on: All except {len(excellent)} excellent ones")
    print(f"   Time estimate: 5-7 days (if sourcing from web)")
    print(f"   Strategy:")
    print(f"   1. All CRITICAL categories → 250+ images each")
    print(f"   2. All HIGH PRIORITY → 250+ images each")
    print(f"   3. ACCEPTABLE categories → 250+ images each")
    print(f"   4. Result: Consistent high performance across all foods")
    
    print("\n⚡ OPTION 3: Quick Win (Reduce categories)")
    print(f"   Remove the {len(critical)} weakest categories from training")
    print(f"   Train on only {len(needs_more) + len(acceptable) + len(excellent)} categories with 100+ images")
    print(f"   Expected accuracy: 80-85% (on smaller set)")
    print(f"   Benefit: Train immediately with higher accuracy")
    print(f"   Drawback: Can't detect those {len(critical)} food types")
    
    # Data sources
    print("\n" + "=" * 90)
    print("🌐 WHERE TO GET IMAGES")
    print("=" * 90)
    
    print("\n1️⃣  KAGGLE DATASETS (Recommended):")
    print("   • Search: 'Indian food dataset', 'food classification'")
    print("   • Download, extract, copy to your dataset folders")
    print("   • Usually high quality and properly labeled")
    
    print("\n2️⃣  GOOGLE IMAGES (Fast but manual):")
    print("   • Use image scraping tools:")
    print("     - google_images_download (Python)")
    print("     - Bulk Image Downloader (Chrome extension)")
    print("   • Search: '[food_name] Indian food', '[food_name] dish'")
    print("   • Download 50-100 per food")
    
    print("\n3️⃣  FOOD DELIVERY APPS:")
    print("   • Swiggy/Zomato have thousands of food images")
    print("   • Screenshot dishes (with permission)")
    print("   • Or use their public datasets if available")
    
    print("\n4️⃣  YOUR OWN PHOTOS:")
    print("   • Visit restaurants")
    print("   • Take 10-20 photos of each dish")
    print("   • Different angles, lighting, plating")
    
    print("\n5️⃣  REDDIT/PINTEREST:")
    print("   • r/IndianFood, r/FoodPorn")
    print("   • Pinterest boards for Indian cuisine")
    print("   • Download images (respect copyright)")
    
    # Quick commands
    print("\n" + "=" * 90)
    print("⚡ QUICK AUTOMATION - Python Script to Download")
    print("=" * 90)
    
    print("\n   Install: pip install google_images_download")
    print("   Then create a script:")
    print("""
   from google_images_download import google_images_download
   
   response = google_images_download.googleimagesdownload()
   
   # For critical categories
   critical_foods = ['khakhra', 'siddu', 'thukpa', 'bhakarwadi']
   
   for food in critical_foods:
       arguments = {
           "keywords": f"{food} Indian food",
           "limit": 80,
           "print_urls": True,
           "output_directory": "downloads"
       }
       response.download(arguments)
   """)
    
    # Summary
    print("\n" + "=" * 90)
    print("📊 SUMMARY & RECOMMENDATION")
    print("=" * 90)
    
    print(f"\n   Current State:")
    print(f"   • {len(critical)} categories are critically low (<100 images)")
    print(f"   • {len(needs_more)} categories need more data (100-149 images)")
    print(f"   • Expected accuracy with current data: 65-70%")
    
    print(f"\n   To Reach 85% Accuracy:")
    print(f"   ✅ Collect {total_needed:,} more images")
    print(f"   ✅ Focus on {len(critical)} critical + {len(needs_more)} high-priority categories")
    print(f"   ✅ Target: 150 images minimum per category")
    print(f"   ✅ Time: 2-4 days if using web sources")
    
    print(f"\n   To Reach 90% Accuracy:")
    print(f"   ✅ Collect {total_ideal:,} more images")
    print(f"   ✅ Target: 250 images per category")
    print(f"   ✅ Time: 5-7 days if using web sources")
    
    print("\n   💡 My Recommendation:")
    print("   1. Start with OPTION 3 (Quick Win): Remove weakest categories, train now")
    print("   2. Get baseline accuracy (likely 75-80% on 39 strong categories)")
    print("   3. Then collect data for removed categories while model is in production")
    print("   4. Retrain with full dataset later")
    
    print("\n   OR")
    
    print("\n   1. Spend 2-4 days collecting images for CRITICAL categories")
    print("   2. Get all categories to 150+ images")
    print("   3. Train and achieve 85% accuracy")
    print("   4. Deploy to production")
    
    print("\n" + "=" * 90)
    
    # Generate shopping list
    print("\n📋 SHOPPING LIST - Export for Easy Reference")
    
    # Create a file
    output_file = Path(__file__).parent / "IMAGE_COLLECTION_LIST.txt"
    with open(output_file, 'w') as f:
        f.write("=" * 90 + "\n")
        f.write("IMAGE COLLECTION PRIORITY LIST\n")
        f.write("Target: 150 images per category (minimum for 85% accuracy)\n")
        f.write("=" * 90 + "\n\n")
        
        f.write("🔴 CRITICAL PRIORITY (Collect these first):\n\n")
        for i, (cat, count) in enumerate(sorted_by_need):
            if count < 100:
                needed = TARGET_MIN - count
                f.write(f"{i+1:2d}. {cat:35s} - Need: {needed:3d} more images\n")
        
        f.write("\n🟡 HIGH PRIORITY:\n\n")
        for i, (cat, count) in enumerate(sorted_by_need):
            if 100 <= count < TARGET_MIN:
                needed = TARGET_MIN - count
                f.write(f"{i+1:2d}. {cat:35s} - Need: {needed:3d} more images\n")
    
    print(f"\n   ✅ Created: {output_file}")
    print(f"   Use this list when collecting images!")
    
    print("\n" + "=" * 90 + "\n")

def main():
    backend_path = Path(__file__).parent
    dataset_path = backend_path / 'dataset'
    
    analyze_for_high_accuracy(dataset_path)

if __name__ == "__main__":
    main()
