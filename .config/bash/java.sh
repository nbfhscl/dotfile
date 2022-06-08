function debugjava {
    java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5050,suspend=y -cp build -ea $1
}
function runjava {
    java -cp build -ea
}

function debugspring {
    mvn -o spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5050 -Dspring.profiles.active=local"
}

function runspring {
    mvn -o spring-boot:run -Dspring-boot.run.jvmArguments="-Dspring.profiles.active=local"
}

function debugjar {
    java -Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=5050,suspend=y -jar $1
}

# source /usr/share/bash-completion/completions/mvn
# source ~/.config/bash/mvn.completion
