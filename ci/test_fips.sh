#!/bin/bash -e
#
# Test Snowflake Connector
# Note this is the script that test_docker.sh runs inside of the docker container
#
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# shellcheck disable=SC1090
CONNECTOR_DIR="$( dirname "${THIS_DIR}")"
CONNECTOR_WHL="$(ls $CONNECTOR_DIR/dist/*cp39*manylinux2014*.whl | sort -r | head -n 1)"

# fetch wiremock
curl https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.11.0/wiremock-standalone-3.11.0.jar --output "${CONNECTOR_DIR}/.wiremock/wiremock-standalone.jar"

python3 -m venv fips_env
source fips_env/bin/activate
pip install -U setuptools pip

# Install pytest-xdist for parallel execution
pip install pytest-xdist

pip install "${CONNECTOR_WHL}[pandas,secure-local-storage,development]"

echo "!!! Environment description !!!"
echo "Default installed OpenSSL version"
openssl version
python -c "import ssl; print('Python openssl library: ' + ssl.OPENSSL_VERSION)"
python -c  "from cryptography.hazmat.backends.openssl import backend;print('Cryptography openssl library: ' + backend.openssl_version_text())"
pip freeze

cd $CONNECTOR_DIR

# Run tests in parallel using pytest-xdist
pytest -n auto -vvv --cov=snowflake.connector --cov-report=xml:coverage.xml test

deactivate
