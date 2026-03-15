def call(String feature) {
    if (feature.startsWith("migration_")) {
        feature = feature.substring("migration_".length())
    }
    if (feature.endsWith(".feature")) {
        feature = feature.substring(0, feature.length() - ".feature".length())
    }
    return feature
}