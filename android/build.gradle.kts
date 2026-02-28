allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

fun org.gradle.api.Project.ensureAndroidNamespace() {
    val androidExt = extensions.findByName("android") ?: return
    val getNamespace =
        androidExt.javaClass.methods.firstOrNull {
            it.name == "getNamespace" && it.parameterCount == 0
        } ?: return
    val setNamespace =
        androidExt.javaClass.methods.firstOrNull {
            it.name == "setNamespace" && it.parameterCount == 1
        } ?: return
    val currentNamespace = getNamespace.invoke(androidExt) as? String
    if (currentNamespace.isNullOrBlank()) {
        val safeProjectName = name.replace(Regex("[^A-Za-z0-9_]"), "_")
        setNamespace.invoke(androidExt, "com.pland.$safeProjectName")
    }
}

subprojects {
    plugins.withId("com.android.application") { ensureAndroidNamespace() }
    plugins.withId("com.android.library") { ensureAndroidNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
