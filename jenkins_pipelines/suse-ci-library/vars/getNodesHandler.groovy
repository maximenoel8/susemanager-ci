def call(Map params) {
    Set<String> nodeList = new HashSet<String>()
    Set<String> envVar = new HashSet<String>()
    def BootstrapRepositoryStatus = [:]
    def CustomChannelStatus       = [:]

    def modules = sh(script: "cd ${env.resultdir}/sumaform; tofu state list", returnStdout: true)
    String[] moduleList = modules.split("\n")

    moduleList.each { line ->
        def parts = line.tokenize(".")
        def nodePart = parts.find { it.contains('minion') || it.contains('client') || it.contains('buildhost') || it.contains('terminal') }
        if (nodePart) {
            def cleanNodeName = nodePart.replaceAll(/\[\d+\]/, "")
            nodeList.add(cleanNodeName)
            envVar.add(cleanNodeName.replaceAll('sles', 'sle').toUpperCase())
        }
    }

    Set<String> nodesToRun = params.minions_to_run.split(', ')
    def disabledNodes = nodeList.findAll { !nodesToRun.contains(it) }
    def envVarDisabledNodes = disabledNodes.collect { it.replaceAll('sles', 'sle').toUpperCase() }
    def nodeListWithoutDisabledNodes = nodeList - disabledNodes

    for (node in nodeListWithoutDisabledNodes) {
        BootstrapRepositoryStatus[node] = 'NOT_CREATED'
        CustomChannelStatus[node]       = 'NOT_CREATED'
    }

    return [
            nodeList: nodeListWithoutDisabledNodes,
            fullNodeList: nodeList,
            envVariableList: envVar,
            envVariableListToDisable: envVarDisabledNodes.join(' '),
            CustomChannelStatus: CustomChannelStatus,
            BootstrapRepositoryStatus: BootstrapRepositoryStatus
    ]
}