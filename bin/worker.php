<?php
/**
 * Trivial worker that polls on a redis list and fires
 * the repo split script.
 *
 * It should be guarded by a supervisor manager such as
 * http://supervisord.org/ or http://mmonit.com/monit/
 *
 * This is far from being secure, use with caution.
 * Anyone with access to the redis instance can trigger
 * the repo split & push process.
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Symfony\Component\Process\Process;
use Symfony\Component\Process\ProcessBuilder;
use Predis\Client;

$redis = new Client();

$logFile = __DIR__ . '/../log/github-webhook.log';
$logger = new Logger('Webhook-worker');
$logger->pushHandler(new StreamHandler($logFile, Logger::DEBUG));

/**
 * Blocking read from redis list. Timeout is indefinite.
 * We use a list directly instead of a mixed SET / LIST
 * approach as described in http://redis.io/commands/blpop
 * since we know for sure that any commit pushed to the
 * list is unique
 */
while ($poppedValue = $redis->blpop('github-split-queue', 0)) {

    $commit = $poppedValue[1];
    $logger->addInfo("Starting split process. HEAD commit is [$commit]");

    $process = (new ProcessBuilder([__DIR__ . '/split.sh']))->getProcess();
    $process->setTimeout(300);
    $process->run(function($type, $buffer) use ($logger) {
        if (Process::ERR === $type) {
            $logger->addError($buffer);
        } else {
            $logger->addInfo($buffer);
        }
    });

    if (!$process->isSuccessful()) {
        $logger->addError('Error splitting repo: ' . $process->getErrorOutput());
        continue;
    }

    $logger->addInfo("Done splitting repo.");
}
