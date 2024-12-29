# Source yo
source ../src

# Run the query
YO_OUTPUT=$(yo "What is the capital of France?")

# Verify that the response contains "Paris"
if [[ $YO_OUTPUT == *"Paris"* ]]; then
  echo "Test passed"
else
  echo "Test failed"
fi