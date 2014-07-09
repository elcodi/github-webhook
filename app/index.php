<?php
require_once __DIR__ . '/../vendor/autoload.php';

use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Process\Process;

$logFile = __DIR__ . '/../log/github-webhook.log';
$ghSecret = getenv('GH_WEBHOOK_SECRET');

$request = Request::createFromGlobals();
$logger = new Logger('Webhook');
$logger->pushHandler(new StreamHandler($logFile, Logger::DEBUG));

$content = ($request->getContent());

$jsonContent = json_decode($content);

if ($jsonContent) {
    if ('refs/heads/master' === $jsonContent->ref) {
        // There is a new push on the master ref,
        // we should split & push the new commits
        // to the repos
        $logger->addInfo("REF [{$jsonContent->ref}] changed, splitting repository");
        $process= new Process(__DIR__ . '/../bin/split.sh');

        $process->run(function($type, $buffer) use ($logger) {

            if (Process::ERR === $type) {
                $logger->addError($buffer);
            } else {
                $logger->addInfo($buffer);
            }

        });

        if (!$process->isSuccessful()) {
            $logger->addInfo('Error splitting repos: ' . $process->getErrorOutput());
            exit(-1);
        }

        $logger->addInfo("Done");
    }
} else {
    $logger->addInfo("Could not parse JSON payload");
    exit -1;
}

exit(0);

