# Use the official R image from the Rocker project
FROM rocker/r-ver:4.4.3

# Install system dependencies required for some R packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up the working directory
WORKDIR /app

# Copy the renv lockfile and install renv
COPY renv.lock renv.lock
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Restore the project's dependencies from the lockfile
RUN R -e "renv::restore()"

# Copy the rest of the project code into the container
COPY . .

# Default command to run when the container starts
CMD ["R"]
