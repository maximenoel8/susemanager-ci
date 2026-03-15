def call(Map params) {
    def migration_tests = [:]

    def features_list = sh(script: "./terracumber-cli ${env.common_params} --runstep cucumber --cucumber-cmd 'ls -1 /root/spacewalk/testsuite/features/build_validation/migration/'", returnStdout: true)
    String[] migration_features = features_list.split("\n").findAll { it.contains("migration_") }

    migration_features.each { feature ->
        def minion = cleanMigrationFeatureName(feature)

        migration_tests["${minion}"] = {
            stage("${minion} migration") {
                runCucumberRakeTarget(target: "cucumber:build_validation_migration_${minion}")
            }
        }
    }
    parallel migration_tests
}