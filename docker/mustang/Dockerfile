FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN wget https://www.mustangproject.org/deploy/Mustang-CLI-2.22.0.jar \
    -O mustang-cli.jar

ENTRYPOINT ["java", "-Xmx1G", "-Dfile.encoding=UTF-8", "-jar", "mustang-cli.jar"]
