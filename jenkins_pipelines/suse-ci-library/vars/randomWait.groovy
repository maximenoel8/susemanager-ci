def call() {
    def randomWait = new Random().nextInt(180)
    println "Waiting for ${randomWait} seconds"
    sleep randomWait
}