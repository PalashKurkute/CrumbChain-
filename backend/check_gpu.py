"""
GPU Detection and CUDA Setup Verification
-----------------------------------------
Checks if your NVIDIA RTX 4050 is properly configured for PyTorch training
"""

import sys

def check_gpu_availability():
    """Check if CUDA GPU is available and print details"""
    
    print("=" * 60)
    print("🔍 GPU AVAILABILITY CHECK")
    print("=" * 60)
    
    try:
        import torch
        print(f"✅ PyTorch version: {torch.__version__}")
        
        # Check CUDA availability
        cuda_available = torch.cuda.is_available()
        print(f"\n{'✅' if cuda_available else '❌'} CUDA Available: {cuda_available}")
        
        if cuda_available:
            # GPU Details
            print(f"\n📊 GPU INFORMATION:")
            print(f"   • GPU Count: {torch.cuda.device_count()}")
            
            for i in range(torch.cuda.device_count()):
                print(f"\n   GPU {i}:")
                print(f"   • Name: {torch.cuda.get_device_name(i)}")
                print(f"   • Compute Capability: {torch.cuda.get_device_capability(i)}")
                
                # VRAM Information
                total_memory = torch.cuda.get_device_properties(i).total_memory / (1024**3)
                print(f"   • Total VRAM: {total_memory:.2f} GB")
                
                # Current memory usage
                allocated = torch.cuda.memory_allocated(i) / (1024**3)
                reserved = torch.cuda.memory_reserved(i) / (1024**3)
                print(f"   • Allocated VRAM: {allocated:.2f} GB")
                print(f"   • Reserved VRAM: {reserved:.2f} GB")
                print(f"   • Available VRAM: {total_memory - reserved:.2f} GB")
            
            # Current device
            current_device = torch.cuda.current_device()
            print(f"\n   • Current Device: cuda:{current_device}")
            
            # Test GPU with small tensor
            print(f"\n🧪 TESTING GPU WITH TENSOR OPERATION...")
            test_tensor = torch.randn(1000, 1000).cuda()
            result = torch.mm(test_tensor, test_tensor)
            print(f"   ✅ GPU tensor operation successful!")
            print(f"   • Test tensor shape: {test_tensor.shape}")
            print(f"   • Test tensor device: {test_tensor.device}")
            
            # Clean up
            del test_tensor, result
            torch.cuda.empty_cache()
            
            print(f"\n{'='*60}")
            print(f"✅ YOUR RTX 4050 IS READY FOR TRAINING!")
            print(f"{'='*60}")
            return True
            
        else:
            print(f"\n{'='*60}")
            print(f"❌ NO CUDA GPU DETECTED!")
            print(f"{'='*60}")
            print(f"\n📝 INSTALLATION INSTRUCTIONS FOR RTX 4050:")
            print(f"\n1. Uninstall existing PyTorch:")
            print(f"   pip uninstall torch torchvision torchaudio")
            print(f"\n2. Install CUDA-enabled PyTorch (for RTX 40-series):")
            print(f"   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121")
            print(f"\n3. Verify CUDA installation:")
            print(f"   python check_gpu.py")
            print(f"\n4. Make sure you have:")
            print(f"   • NVIDIA GPU Driver (latest)")
            print(f"   • CUDA Toolkit 12.1+ installed")
            print(f"\n{'='*60}")
            return False
            
    except ImportError:
        print(f"\n❌ PyTorch is not installed!")
        print(f"\n📝 INSTALLATION COMMAND:")
        print(f"   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121")
        print(f"\n{'='*60}")
        return False
    
    except Exception as e:
        print(f"\n❌ Error during GPU check: {e}")
        import traceback
        traceback.print_exc()
        return False


def check_tensorflow_gpu():
    """Check if TensorFlow can see the GPU"""
    print(f"\n{'='*60}")
    print(f"🔍 TENSORFLOW GPU CHECK")
    print(f"{'='*60}")
    
    try:
        import tensorflow as tf
        print(f"✅ TensorFlow version: {tf.__version__}")
        
        gpus = tf.config.list_physical_devices('GPU')
        print(f"\n{'✅' if gpus else '❌'} TensorFlow GPU Count: {len(gpus)}")
        
        if gpus:
            for gpu in gpus:
                print(f"   • {gpu}")
            print(f"\n✅ TensorFlow can use your GPU!")
        else:
            print(f"\n⚠️  TensorFlow cannot detect GPU")
            print(f"   Your current model uses TensorFlow, but PyTorch is better for RTX 4050")
            
    except ImportError:
        print(f"⚠️  TensorFlow not found (this is OK if using PyTorch)")
    except Exception as e:
        print(f"❌ TensorFlow GPU check failed: {e}")


if __name__ == "__main__":
    gpu_available = check_gpu_availability()
    check_tensorflow_gpu()
    
    if not gpu_available:
        sys.exit(1)
    
    print(f"\n🚀 Ready to train on RTX 4050 with 6GB VRAM!")
    sys.exit(0)
