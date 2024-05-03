# Default target: run simulation
all: run

# Clean target: remove generated files
clean:
	rm -rf worklib xcelium.d *.log *.history

# Compile and elaborate design
compile:
	xrun -f run.f -compile -access +rwc

# Elaborate design (if already compiled)
elaborate:
	xrun -f run.f -elaborate

# Run simulation
run: elaborate
	xrun -f run.f -R

# Run with GUI
run-gui: elaborate
	xrun -f run.f -gui -access +rwc

# Run simulation with clean build
run-clean: clean compile run
