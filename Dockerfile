# Stage 1: Build the application using Maven
FROM maven:3.8.2-openjdk-8 AS mavenbuilder

# Define build argument
ARG TEST=/var/lib/

# Set working directory
WORKDIR ${TEST}

# Copy source code
COPY . .

# Build the WAR file
RUN mvn clean package


# Stage 2: Deploy WAR file to Tomcat
FROM tomcat:jre8-temurin-focal

# Define argument again for this stage
ARG TEST=/var/lib/

# Copy WAR file from builder stage to Tomcat webapps
COPY --from=mavenbuilder ${TEST}/target/*.war /usr/local/tomcat/webapps/
