#!/bin/bash

##############################################################################
# run_sim.sh - Script to run RISC-V Core simulation using ModelSim
##############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Project directories
RTL_DIR="$ROOT_DIR/rtl"
DV_DIR="$ROOT_DIR/dv"
PKG_DIR="$ROOT_DIR/pkg"
INC_DIR="$ROOT_DIR/includes"
WORK_DIR="$ROOT_DIR/work"

# ModelSim work library
WORK_LIB="work"

# Testbench top module
TB_TOP="tb_top"

# Parse command line arguments
GUI_MODE=0
CLEAN_FIRST=1
COMPILE_ONLY=0

print_usage() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Options:"
    echo "  -g, --gui           Run simulation in GUI mode"
    echo "  -c, --compile-only  Compile only, don't run simulation"
    echo "  -n, --no-clean      Don't clean before compilation"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run simulation in console mode"
    echo "  $0 -g               # Run simulation in GUI mode"
    echo "  $0 -c               # Compile only"
    echo "  $0 -g -n            # Run GUI without cleaning first"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--gui)
            GUI_MODE=1
            shift
            ;;
        -c|--compile-only)
            COMPILE_ONLY=1
            shift
            ;;
        -n|--no-clean)
            CLEAN_FIRST=0
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if ModelSim is available
check_modelsim() {
    if ! command -v vsim &> /dev/null; then
        print_error "ModelSim not found in PATH!"
        print_info "Please make sure ModelSim is installed and added to your PATH."
        exit 1
    fi
    print_success "ModelSim found: $(which vsim)"
}

# Clean work directory
clean_work() {
    print_info "Cleaning work directory..."
    cd "$WORK_DIR" || exit 1
    rm -rf $WORK_LIB
    rm -rf transcript
    rm -rf vsim.wlf
    rm -rf *.log
    print_success "Clean complete!"
}

# Create work library
create_library() {
    print_info "Creating work library..."
    cd "$WORK_DIR" || exit 1
    vlib $WORK_LIB
    if [ $? -ne 0 ]; then
        print_error "Failed to create work library!"
        exit 1
    fi
    print_success "Work library created!"
}

# Compile source files
compile_sources() {
    print_info "Compiling source files..."
    cd "$WORK_DIR" || exit 1
    
    # Compile package files
    print_info "Compiling package files..."
    vlog -sv +incdir+$INC_DIR -work $WORK_LIB -timescale=1ns/1ps \
        $PKG_DIR/core_pkg.sv
    if [ $? -ne 0 ]; then
        print_error "Failed to compile package files!"
        exit 1
    fi
    
    # Compile RTL files
    print_info "Compiling RTL files..."
    vlog -sv +incdir+$INC_DIR -work $WORK_LIB -timescale=1ns/1ps \
        $RTL_DIR/decoder.sv \
        $RTL_DIR/core.sv
    if [ $? -ne 0 ]; then
        print_error "Failed to compile RTL files!"
        exit 1
    fi
    
    # Compile testbench files
    print_info "Compiling testbench files..."
    vlog -sv +incdir+$INC_DIR -work $WORK_LIB -timescale=1ns/1ps \
        $DV_DIR/tb_top.sv
    if [ $? -ne 0 ]; then
        print_error "Failed to compile testbench files!"
        exit 1
    fi
    
    print_success "Compilation complete!"
}

# Run simulation
run_simulation() {
    print_info "Running simulation..."
    cd "$WORK_DIR" || exit 1
    
    if [ $GUI_MODE -eq 1 ]; then
        print_info "Starting ModelSim GUI..."
        vsim -voptargs=+acc -do "add wave -recursive /*; run -all" $WORK_LIB.$TB_TOP
    else
        print_info "Running in console mode..."
        vsim -c -voptargs=+acc -do "run -all; quit -f" $WORK_LIB.$TB_TOP
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Simulation complete!"
    else
        print_error "Simulation failed!"
        exit 1
    fi
}

# Main execution flow
main() {
    print_info "Starting RISC-V Core simulation script..."
    
    # Check if ModelSim is available
    check_modelsim
    
    # Clean if requested
    if [ $CLEAN_FIRST -eq 1 ]; then
        clean_work
    fi
    
    # Create library
    create_library
    
    # Compile sources
    compile_sources
    
    # Run simulation if not compile-only mode
    if [ $COMPILE_ONLY -eq 0 ]; then
        run_simulation
    else
        print_success "Compile-only mode: Skipping simulation"
    fi
    
    print_success "Script execution complete!"
}

# Run main function
main