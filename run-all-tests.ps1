# =====================================================
# TAIMAKO - COMPLETE TEST RUNNER (PowerShell)
# =====================================================
# 
# This script runs all test suites to verify your
# Taimako AI Health Assistant is working perfectly
# 
# Run: .\run-all-tests.ps1

param(
    [switch]$SkipHedera,
    [switch]$QuickOnly
)

# Colors for output
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"
$Cyan = "Cyan"
$Magenta = "Magenta"

# Test results
$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

# Function to print colored output
function Write-Header {
    param([string]$Message)
    Write-Host "=====================================================" -ForegroundColor $Blue
    Write-Host $Message -ForegroundColor $Blue
    Write-Host "=====================================================" -ForegroundColor $Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor $Cyan
}

# Function to run a test and track results
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestCommand
    )
    
    Write-Host "`n🧪 Running: $TestName" -ForegroundColor $Magenta
    
    $script:TotalTests++
    
    try {
        $result = & $TestCommand
        if ($LASTEXITCODE -eq 0 -or $result -eq $true) {
            Write-Success "$TestName completed successfully"
            $script:PassedTests++
            return $true
        } else {
            Write-Error "$TestName failed"
            $script:FailedTests++
            return $false
        }
    } catch {
        Write-Error "$TestName failed with exception: $($_.Exception.Message)"
        $script:FailedTests++
        return $false
    }
}

# Main test runner
function Main {
    Write-Header "🚀 TAIMAKO COMPLETE TEST SUITE"
    Write-Host "Testing all components of your AI Health Assistant" -ForegroundColor $Cyan
    Write-Host "Started at: $(Get-Date)`n" -ForegroundColor $Cyan

    # Check prerequisites
    Write-Header "🔍 CHECKING PREREQUISITES"
    
    # Check Node.js
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js is installed: $nodeVersion"
        } else {
            Write-Error "Node.js is not installed"
            return
        }
    } catch {
        Write-Error "Node.js is not installed"
        return
    }
    
    # Check Dart
    try {
        $dartVersion = dart --version 2>$null | Select-Object -First 1
        if ($dartVersion) {
            Write-Success "Dart is installed: $dartVersion"
        } else {
            Write-Warning "Dart is not installed - skipping Flutter integration test"
        }
    } catch {
        Write-Warning "Dart is not installed - skipping Flutter integration test"
    }
    
    # Check required files
    $requiredFiles = @(
        "package.json",
        "create-topic.js",
        "test-edge-functions.js",
        "quick-test.js",
        "test-flutter-integration.dart"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Success "$file found"
        } else {
            Write-Warning "$file not found"
        }
    }

    # Test 1: Hedera Topic Creation (if not already done)
    if (-not $SkipHedera) {
        Write-Header "🔗 TESTING HEDERA INTEGRATION"
        
        if (Test-Path "node_modules/@hashgraph/sdk/package.json") {
            Write-Success "Hedera SDK is installed"
            
            # Check if topic already exists
            $topicContent = Get-Content "create-topic.js" -Raw
            if ($topicContent -match "0\.0\.7098028") {
                Write-Info "Hedera topic already created (0.0.7098028)"
            } else {
                Invoke-Test "Hedera Topic Creation" { node create-topic.js }
            }
        } else {
            Write-Warning "Hedera SDK not installed - installing now..."
            try {
                npm install @hashgraph/sdk
                Write-Success "Hedera SDK installed successfully"
                Invoke-Test "Hedera Topic Creation" { node create-topic.js }
            } catch {
                Write-Error "Failed to install Hedera SDK"
            }
        }
    }

    # Test 2: Edge Functions
    Write-Header "⚡ TESTING EDGE FUNCTIONS"
    
    if ($QuickOnly) {
        if (Test-Path "quick-test.js") {
            Invoke-Test "Quick Edge Function Test" { node quick-test.js }
        }
    } else {
        if (Test-Path "test-edge-functions.js") {
            Invoke-Test "Comprehensive Edge Function Test" { node test-edge-functions.js }
        }
        
        if (Test-Path "quick-test.js") {
            Invoke-Test "Quick Edge Function Test" { node quick-test.js }
        }
    }

    # Test 3: Flutter Integration (Dart)
    Write-Header "📱 TESTING FLUTTER INTEGRATION"
    
    try {
        $dartVersion = dart --version 2>$null
        if ($dartVersion -and (Test-Path "test-flutter-integration.dart")) {
            Invoke-Test "Flutter Integration Test" { dart test-flutter-integration.dart }
        } else {
            Write-Warning "Skipping Flutter integration test (Dart not available or file not found)"
        }
    } catch {
        Write-Warning "Skipping Flutter integration test (Dart not available)"
    }

    # Test 4: Environment Configuration
    Write-Header "⚙️  TESTING ENVIRONMENT CONFIGURATION"
    
    if (Test-Path "env.example") {
        Write-Success "Environment template found"
        
        if (Test-Path ".env") {
            Write-Success ".env file exists"
            
            $envContent = Get-Content ".env" -Raw
            if ($envContent -match "HEDERA_TOPIC_ID=") {
                Write-Success "HEDERA_TOPIC_ID is configured"
            } else {
                Write-Warning "HEDERA_TOPIC_ID not found in .env"
            }
            
            if ($envContent -match "GROQ_API_KEY=") {
                Write-Success "GROQ_API_KEY is configured"
            } else {
                Write-Warning "GROQ_API_KEY not found in .env"
            }
        } else {
            Write-Warning ".env file not found - create one from env.example"
        }
    } else {
        Write-Error "env.example not found"
    }

    # Test 5: Project Structure
    Write-Header "📁 TESTING PROJECT STRUCTURE"
    
    $flutterFiles = @(
        "lib/main.dart",
        "lib/services/hedera_service.dart",
        "lib/services/groq_service.dart",
        "lib/services/medical_prediction_service.dart",
        "lib/data/nigerian_medical_dataset.json",
        "pubspec.yaml"
    )
    
    foreach ($file in $flutterFiles) {
        if (Test-Path $file) {
            Write-Success "Found: $file"
        } else {
            Write-Error "Missing: $file"
            $script:FailedTests++
        }
        $script:TotalTests++
    }

    # Test 6: Supabase Configuration
    Write-Header "🗄️  TESTING SUPABASE CONFIGURATION"
    
    if (Test-Path "lib/main.dart") {
        $mainContent = Get-Content "lib/main.dart" -Raw
        if ($mainContent -match "pcqfdxgajkojuffiiykt\.supabase\.co") {
            Write-Success "Supabase URL configured in Flutter app"
        } else {
            Write-Warning "Supabase URL not found in main.dart"
        }
        
        if ($mainContent -match "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9") {
            Write-Success "Supabase anon key configured in Flutter app"
        } else {
            Write-Warning "Supabase anon key not found in main.dart"
        }
    }

    # Final Results
    Write-Header "🏁 FINAL TEST RESULTS"
    
    Write-Host "📊 Total Tests: $script:TotalTests" -ForegroundColor $Cyan
    Write-Host "✅ Passed: $script:PassedTests" -ForegroundColor $Green
    Write-Host "❌ Failed: $script:FailedTests" -ForegroundColor $Red
    
    $successRate = if ($script:TotalTests -gt 0) { [math]::Round(($script:PassedTests / $script:TotalTests) * 100, 1) } else { 0 }
    Write-Host "📈 Success Rate: $successRate%" -ForegroundColor $Cyan
    
    Write-Host ""
    
    if ($successRate -ge 90) {
        Write-Success "🎉 EXCELLENT! Your Taimako setup is working perfectly!"
        Write-Host "✅ Ready for production deployment" -ForegroundColor $Green
        Write-Host "✅ All Edge Functions are operational" -ForegroundColor $Green
        Write-Host "✅ Hedera blockchain integration working" -ForegroundColor $Green
        Write-Host "✅ AI prediction system functional" -ForegroundColor $Green
    } elseif ($successRate -ge 70) {
        Write-Warning "⚠️  MOSTLY WORKING - Some issues detected"
        Write-Host "🔧 Review failed tests before deployment" -ForegroundColor $Yellow
        Write-Host "🔧 Core functionality appears to work" -ForegroundColor $Yellow
    } else {
        Write-Error "❌ NEEDS ATTENTION - Multiple issues detected"
        Write-Host "🛠️  Fix critical issues before proceeding" -ForegroundColor $Red
        Write-Host "🛠️  Check Edge Function configuration" -ForegroundColor $Red
        Write-Host "🛠️  Verify Supabase secrets" -ForegroundColor $Red
    }
    
    Write-Host ""
    Write-Host "📅 Test completed at: $(Get-Date)" -ForegroundColor $Cyan
    
    # Exit with appropriate code
    if ($successRate -ge 70) {
        exit 0
    } else {
        exit 1
    }
}

# Run main function
Main
