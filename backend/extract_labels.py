import torch
import os

# Load the trained model
model_path = os.path.join(os.path.dirname(__file__), 'models', 'best_food_model_combined.pth')
checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)

# Extract food labels
food_labels = checkpoint['food_labels']
print(f"Total categories: {len(food_labels)}")
print(f"\nFood categories:\n{food_labels}")

# Save to labels file
labels_path = os.path.join(os.path.dirname(__file__), 'models', 'labels_combined.txt')
with open(labels_path, 'w') as f:
    for label in food_labels:
        f.write(f"{label}\n")

print(f"\n✅ Labels saved to: {labels_path}")
print(f"   Total: {len(food_labels)} food categories")
