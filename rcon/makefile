.PHONY: clean build-lambda

# Variables
PACKAGE_DIR = package
SHUTDOWN_ZIP_FILE = shutdown_lambda_function.zip
PYTHON_VERSION = 3.9
REQUIREMENTS = factorio-rcon-py boto3

build-shutdown-lambda: clean
	# Create package directory
	mkdir -p $(PACKAGE_DIR)
	
	# Copy lambda function
	cp announce_shutdown.py $(PACKAGE_DIR)/
	
	# Install dependencies
	pip install --target $(PACKAGE_DIR) $(REQUIREMENTS)
	
	# Create zip file
	cd $(PACKAGE_DIR) && zip -r ../$(SHUTDOWN_ZIP_FILE) .

	# move it to infra folder
	mv $(SHUTDOWN_ZIP_FILE) ./infrastructure/

clean:
	# Remove previous builds
	rm -rf $(PACKAGE_DIR)
	rm -f $(SHUTDOWN_ZIP_FILE)

test: build-lambda
	# List contents of zip file
	unzip -l $(SHUTDOWN_ZIP_FILE)