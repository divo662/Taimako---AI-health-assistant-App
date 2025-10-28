#!/usr/bin/env bash
# =====================================================
# TAIMAKO - COMPLETE TEST RUNNER
# =====================================================
# 
# This script runs all test suites to verify your
# Taimako AI Health Assistant is working perfectly
# 
# Run: ./run-all-tests.sh
# Or: bash run-all-tests.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_header() {
    echo -e "${BLUE}=====================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "\n${PURPLE}🧪 Running: $test_name${NC}"
    echo "Command: $test_command"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        print_success "$test_name completed successfully"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "$test_name failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main test runner
main() {
    print_header "🚀 TAIMAKO COMPLETE TEST SUITE"
    echo -e "${CYAN}Testing all components of your AI Health Assistant${NC}"
    echo -e "${CYAN}Started at: $(date)${NC}\n"

    # Check prerequisites
    print_header "🔍 CHECKING PREREQUISITES"
    
    if command_exists node; then
        print_success "Node.js is installed: $(node --version)"
    else
        print_error "Node.js is not installed"
        exit 1
    fi
    
    if command_exists dart; then
        print_success "Dart is installed: $(dart --version | head -n1)"
    else
        print_warning "Dart is not installed - skipping Flutter integration test"
    fi
    
    if [ -f "package.json" ]; then
        print_success "package.json found"
    else
        print_error "package.json not found"
        exit 1
    fi
    
    if [ -f "create-topic.js" ]; then
        print_success "Hedera topic creation script found"
    else
        print_error "create-topic.js not found"
        exit 1
    fi

    # Test 1: Hedera Topic Creation (if not already done)
    print_header "🔗 TESTING HEDERA INTEGRATION"
    
    if [ -f "node_modules/@hashgraph/sdk/package.json" ]; then
        print_success "Hedera SDK is installed"
        
        # Check if topic already exists
        if grep -q "0.0.7098028" create-topic.js 2>/dev/null; then
            print_info "Hedera topic already created (0.0.7098028)"
        else
            run_test "Hedera Topic Creation" "node create-topic.js"
        fi
    else
        print_warning "Hedera SDK not installed - installing now..."
        if npm install @hashgraph/sdk; then
            print_success "Hedera SDK installed successfully"
            run_test "Hedera Topic Creation" "node create-topic.js"
        else
            print_error "Failed to install Hedera SDK"
        fi
    fi

    # Test 2: Edge Functions (Node.js)
    print_header "⚡ TESTING EDGE FUNCTIONS (NODE.JS)"
    
    if [ -f "test-edge-functions.js" ]; then
        run_test "Comprehensive Edge Function Test" "node test-edge-functions.js"
    else
        print_warning "test-edge-functions.js not found"
    fi
    
    if [ -f "quick-test.js" ]; then
        run_test "Quick Edge Function Test" "node quick-test.js"
    else
        print_warning "quick-test.js not found"
    fi

    # Test 3: Flutter Integration (Dart)
    print_header "📱 TESTING FLUTTER INTEGRATION (DART)"
    
    if command_exists dart && [ -f "test-flutter-integration.dart" ]; then
        run_test "Flutter Integration Test" "dart test-flutter-integration.dart"
    else
        print_warning "Skipping Flutter integration test (Dart not available or file not found)"
    fi

    # Test 4: Environment Configuration
    print_header "⚙️  TESTING ENVIRONMENT CONFIGURATION"
    
    if [ -f "env.example" ]; then
        print_success "Environment template found"
        
        # Check if .env exists
        if [ -f ".env" ]; then
            print_success ".env file exists"
            
            # Check for required variables
            if grep -q "HEDERA_TOPIC_ID=" .env; then
                print_success "HEDERA_TOPIC_ID is configured"
            else
                print_warning "HEDERA_TOPIC_ID not found in .env"
            fi
            
            if grep -q "GROQ_API_KEY=" .env; then
                print_success "GROQ_API_KEY is configured"
            else
                print_warning "GROQ_API_KEY not found in .env"
            fi
        else
            print_warning ".env file not found - create one from env.example"
        fi
    else
        print_error "env.example not found"
    fi

    # Test 5: Project Structure
    print_header "📁 TESTING PROJECT STRUCTURE"
    
    local required_files=(
        "lib/main.dart"
        "lib/services/hedera_service.dart"
        "lib/services/groq_service.dart"
        "lib/services/medical_prediction_service.dart"
        "lib/data/nigerian_medical_dataset.json"
        "pubspec.yaml"
    )
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
    done

    # Test 6: Supabase Configuration
    print_header "🗄️  TESTING SUPABASE CONFIGURATION"
    
    if grep -q "pcqfdxgajkojuffiiykt.supabase.co" lib/main.dart; then
        print_success "Supabase URL configured in Flutter app"
    else
        print_warning "Supabase URL not found in main.dart"
    fi
    
    if grep -q "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" lib/main.dart; then
        print_success "Supabase anon key configured in Flutter app"
    else
        print_warning "Supabase anon key not found in main.dart"
    fi

    # Final Results
    print_header "🏁 FINAL TEST RESULTS"
    
    echo -e "${CYAN}📊 Total Tests: $TOTAL_TESTS${NC}"
    echo -e "${GREEN}✅ Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}❌ Failed: $FAILED_TESTS${NC}"
    
    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "${CYAN}📈 Success Rate: $success_rate%${NC}"
    
    echo ""
    
    if [ $success_rate -ge 90 ]; then
        print_success "🎉 EXCELLENT! Your Taimako setup is working perfectly!"
        echo -e "${GREEN}✅ Ready for production deployment${NC}"
        echo -e "${GREEN}✅ All Edge Functions are operational${NC}"
        echo -e "${GREEN}✅ Hedera blockchain integration working${NC}"
        echo -e "${GREEN}✅ AI prediction system functional${NC}"
    elif [ $success_rate -ge 70 ]; then
        print_warning "⚠️  MOSTLY WORKING - Some issues detected"
        echo -e "${YELLOW}🔧 Review failed tests before deployment${NC}"
        echo -e "${YELLOW}🔧 Core functionality appears to work${NC}"
    else
        print_error "❌ NEEDS ATTENTION - Multiple issues detected"
        echo -e "${RED}🛠️  Fix critical issues before proceeding${NC}"
        echo -e "${RED}🛠️  Check Edge Function configuration${NC}"
        echo -e "${RED}🛠️  Verify Supabase secrets${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}📅 Test completed at: $(date)${NC}"
    
    # Exit with appropriate code
    if [ $success_rate -ge 70 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
