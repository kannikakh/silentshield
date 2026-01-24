allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}