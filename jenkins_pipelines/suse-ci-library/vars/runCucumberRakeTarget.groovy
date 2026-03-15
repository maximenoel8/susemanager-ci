def call(Map args) {
    def target = args.target
    def params = args.params ?: [:]
    def disableMinions = args.disableMinions ?: null
    def customExports = args.customExports ?: ""
    def returnStatus = args.returnStatus ?: false

    def unset_vars = ""
    if (disableMinions) {
        def list_to_join = disableMinions instanceof String ? disableMinions.split(' ') : disableMinions
        unset_vars = list_to_join ? "unset ${list_to_join.join(' ')}; " : ""
    }

    def scriptToRun = """
        ./terracumber-cli ${env.common_params} \\
            --logfile ${env.resultdirbuild}/testsuite.log \\
            --runstep cucumber \\
            --cucumber-cmd '${unset_vars}${env.exports} ${customExports} cd /root/spacewalk/testsuite; rake ${target}'
    """.stripIndent().trim()

    // If returnStatus is requested (for soft fails), return it.
    // Otherwise, fail fast natively.
    if (returnStatus) {
        return sh(script: scriptToRun, returnStatus: true)
    } else {
        sh scriptToRun
    }
}