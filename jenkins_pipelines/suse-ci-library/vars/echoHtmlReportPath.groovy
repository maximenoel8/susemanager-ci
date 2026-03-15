def call(String rake_target) {
    def path_export_url = "http://${env.controller_hostname}/results/${env.BUILD_NUMBER}/${rake_target}_html_path.txt"

    try {
        def response = httpRequest(url: path_export_url, throwExceptionOnError: true, quiet: true)
        if (response.status == 200) {
            def full_html_url = "http://${env.controller_hostname}/${response.content.trim()}"
            echo "HTML Report URL: ${full_html_url}"
        } else {
            echo "Warning: Failed to fetch HTML path file. HTTP Status: ${response.status}"
        }
    } catch (Exception e) {
        echo "Error fetching HTML path from ${path_export_url}: ${e.getMessage()}"
    }
}