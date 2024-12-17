# Use Python base image
FROM python:3.9

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir flask boto3 botocore

# Expose the Flask port
EXPOSE 8000

# Start the Flask app
CMD ["python", "app.py"]
