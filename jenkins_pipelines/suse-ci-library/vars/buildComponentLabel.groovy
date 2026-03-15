def call(String component, Map params, Map conditionsMap, boolean isEnabled) {
    if (!isEnabled) return null

    def options = []
    for (entry in conditionsMap) {
        if (params.get(entry.key)) {
            options << entry.value
        }
    }
    return options ? "${component}[${options.join(' ')}]" : null
}