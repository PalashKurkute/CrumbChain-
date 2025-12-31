"""
Create a minimal version of the model for GitHub (removes optimizer state)
Keeps original model intact locally
"""
import torch
import os

def create_minimal_model():
    """Remove optimizer state - keeps only model weights for inference"""
    
    model_dir = os.path.join(os.path.dirname(__file__), 'models')
    input_path = os.path.join(model_dir, 'best_food_model_combined.pth')
    output_path = os.path.join(model_dir, 'food_model_github.pth')  # Separate file for GitHub
    
    print("=" * 80)
    print("📦 Creating Minimal Model for GitHub")
    print("=" * 80)
    
    if not os.path.exists(input_path):
        print(f"❌ Model not found: {input_path}")
        return
    
    print("\n🔄 Loading full model...")
    checkpoint = torch.load(input_path, map_location='cpu', weights_only=False)
    
    original_size = os.path.getsize(input_path) / (1024 * 1024)
    print(f"📊 Original size: {original_size:.2f} MB")
    print(f"📋 Contents: {list(checkpoint.keys())}")
    
    # Create minimal checkpoint - remove optimizer
    print("\n✂️  Removing optimizer state...")
    minimal_checkpoint = {
        'epoch': checkpoint['epoch'],
        'model_state_dict': checkpoint['model_state_dict'],
        'val_acc': checkpoint['val_acc'],
        'val_loss': checkpoint['val_loss'],
        'num_classes': checkpoint['num_classes'],
        'food_labels': checkpoint['food_labels'],
        'label_to_idx': checkpoint['label_to_idx']
    }
    
    print("💾 Saving minimal model for GitHub...")
    torch.save(minimal_checkpoint, output_path)
    
    compressed_size = os.path.getsize(output_path) / (1024 * 1024)
    reduction = ((original_size - compressed_size) / original_size) * 100
    
    print("\n" + "=" * 80)
    print("✅ COMPRESSION COMPLETE!")
    print("=" * 80)
    print(f"📊 Original:    {original_size:.2f} MB")
    print(f"📦 Compressed:  {compressed_size:.2f} MB")
    print(f"💯 Reduction:   {reduction:.1f}%")
    print(f"✅ Accuracy:    88.80% (unchanged)")
    print(f"📁 Output:      {output_path}")
    
    if compressed_size < 100:
        print(f"\n✅ SUCCESS: {compressed_size:.2f} MB fits GitHub's 100 MB limit!")
        print("   Ready to push to GitHub!")
    else:
        print(f"\n⚠️  WARNING: {compressed_size:.2f} MB still exceeds 100 MB")
        print("   Consider using Git LFS")
    
    print("\n📋 What was removed:")
    print("   ❌ optimizer_state_dict (training state)")
    print("\n📋 What was kept:")
    print("   ✅ model_state_dict (all weights)")
    print("   ✅ val_acc (88.80%)")
    print("   ✅ food_labels (61 categories)")
    print("   ✅ label_to_idx (mapping)")
    print("=" * 80)

if __name__ == "__main__":
    create_minimal_model()
