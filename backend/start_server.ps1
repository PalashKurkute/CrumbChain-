# CrumbChain Backend Startup Script
# Automatically activates venv_gpu and starts Flask server with PyTorch support

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   CrumbChain Backend Startup" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan

# Check if venv_gpu exists
if (-not (Test-Path ".\venv_gpu\Scripts\Activate.ps1")) {
    Write-Host "❌ Virtual environment not found!" -ForegroundColor Red
    Write-Host "   Creating venv_gpu..." -ForegroundColor Yellow
    python -m venv venv_gpu
    
    Write-Host "   Installing dependencies..." -ForegroundColor Yellow
    .\venv_gpu\Scripts\Activate.ps1
    
    Write-Host "   Installing PyTorch with CUDA..." -ForegroundColor Yellow
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    
    Write-Host "   Installing Flask dependencies..." -ForegroundColor Yellow
    pip install flask flask-cors pymongo python-dotenv bcrypt pyjwt werkzeug pillow numpy pandas tqdm
    
    Write-Host "✅ Virtual environment setup complete!" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Cyan
& .\venv_gpu\Scripts\Activate.ps1

# Check if in correct directory
if (-not (Test-Path ".\app.py")) {
    Write-Host "❌ app.py not found!" -ForegroundColor Red
    Write-Host "   Make sure you're in the backend directory" -ForegroundColor Yellow
    exit 1
}

# Display server info
Write-Host ""
Write-Host "📊 Server Information:" -ForegroundColor Green
Write-Host "   • Python: " -NoNewline
python --version
Write-Host "   • PyTorch Model: EfficientNetB2 (80 classes, 72.68% accuracy)" -ForegroundColor Cyan
Write-Host "   • TensorFlow Model: InceptionV3 (20 classes, fallback)" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Server will be available at:" -ForegroundColor Green
Write-Host "   • Local:   http://127.0.0.1:5000" -ForegroundColor Yellow
Write-Host "   • Network: http://192.168.0.100:5000" -ForegroundColor Yellow
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   Starting Flask server..." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Start the Flask server
python app.py
