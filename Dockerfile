# ==========================================================
# STAGE 1 : BUILD
# Utilise une image Maven avec JDK pour compiler l'application
# ==========================================================
FROM maven:3.9-eclipse-temurin-17 AS builder

# Répertoire de travail dans le conteneur de build
WORKDIR /app

# Copier d'abord le pom.xml pour exploiter le cache Docker
COPY pom.xml .

# Télécharger toutes les dépendances
RUN mvn dependency:go-offline -B

# Copier le code source
COPY src ./src

# Compiler et packager l'application
RUN mvn clean package -DskipTests -B

# ==========================================================
# STAGE 2 : RUNTIME
# Image légère avec seulement le JRE
# ==========================================================
FROM eclipse-temurin:17-jre-alpine AS runtime

# Métadonnées
LABEL version="1.0"
LABEL description="Spring Boot Application"

# Créer un utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Répertoire de travail
WORKDIR /app

# Copier uniquement le JAR depuis le stage de build
COPY --from=builder /app/target/*.jar app.jar

# Donner les droits à l'utilisateur non-root
RUN chown -R appuser:appgroup /app

# Utiliser l'utilisateur non-root
USER appuser

# Exposer le port de l'application
EXPOSE 8080

# Variables d'environnement
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"
ENV SPRING_PROFILES_ACTIVE=prod

# Commande de démarrage
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]