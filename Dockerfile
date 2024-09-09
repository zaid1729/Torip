# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Install Tor and other dependencies
RUN apt-get update && apt-get install -y tor curl torsocks && \
    rm -rf /var/lib/apt/lists/*

# Set up the virtual environment
RUN python3 -m venv /env

# Install Python dependencies
COPY requirements.txt .
RUN /env/bin/pip install -r requirements.txt

# Copy the script into the container
COPY change_ip.sh /usr/local/bin/

# Make the script executable
RUN chmod +x /usr/local/bin/change_ip.sh

# Expose Tor control port
EXPOSE 9051

# Run the script
CMD ["/usr/local/bin/change_ip.sh"]
