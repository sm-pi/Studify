allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- PASTE THIS FIX BELOW AT THE BOTTOM OF THE FILE ---

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            // Fix for androidx.activity:activity:1.11.0
            if (requested.group == "androidx.activity" && requested.name == "activity") {
                useVersion("1.9.3")
            }

            // Fix for androidx.browser:browser:1.9.0
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }

            // Fix for androidx.core:core:1.17.0
            if (requested.group == "androidx.core" && requested.name == "core") {
                useVersion("1.13.1")
            }

            // Fix for androidx.core:core-ktx:1.17.0
            if (requested.group == "androidx.core" && requested.name == "core-ktx") {
                useVersion("1.13.1")
            }
        }
    }
}