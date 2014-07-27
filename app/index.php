<?php

/**
 * This file is part of the Elcodi package.
 *
 * Copyright (c) 2014 Elcodi.com
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Feel free to edit as you please, and have fun.
 *
 * @author Marc Morera <yuhu@mmoreram.com>
 * @author Aldo Chiecchia <zimage@tiscali.it>
 */

require_once __DIR__ . '/../vendor/autoload.php';

use Monolog\Logger;
use Monolog\Handler\StreamHandler;
use Symfony\Component\HttpFoundation\Request;
use Predis\Client;
use Predis\Connection\ConnectionException;

$logFile = __DIR__ . '/../log/github-webhook.log';
$logger = new Logger('Webhook');
$logger->pushHandler(new StreamHandler($logFile, Logger::DEBUG));

$ghSecret = getenv('GH_WEBHOOK_SECRET');
if (!$ghSecret) {
    $logger->addError('Environment variable GH_WEBHOOK_SECRET must be set to github webhook secret.');
    exit(-1);
}

// Default localhost connection
$redis = new Client();

$request = Request::createFromGlobals();
$content = $request->getContent();

$jsonContent = json_decode($content);

/**
 * Signature has to be computed according to
 * https://developer.github.com/webhooks/securing/
 */
$computedSignature = 'sha1=' . hash_hmac('sha1', $content, $ghSecret);
$githubSignature = $request->headers->get('X-Hub-Signature');
$logger->addInfo('GitHub webhook signature is: ' . $githubSignature);

// Secure compare signatures before proceeding
if (!secureCompare($githubSignature, $computedSignature)) {
    $logger->addError('Signature mismatch. Aborting.');
    exit(-1);
}

if ($jsonContent) {

    // Event should be 'push'
    $githubEvent = $request->headers->get('X-Github-Event');

    if ('push' === $githubEvent && 'refs/heads/master' === $jsonContent->ref) {

        /**
         * There is a new push on the master ref,
         * we should split & push the new commits
         * to the repos
         */
        $commit = $jsonContent->head_commit->id;
        $logger->addInfo("Github event [$githubEvent]. New commit [$commit] for [{$jsonContent->ref}]. Splitting repository");

        // Adding $commit to the work queue
        try {
            $redis->rpush('github-split-queue', $commit);
        } catch (ConnectionException $e) {
            $logger->addError('Unable to connect to redis: ' . $e->getMessage());
            exit -1;
        }

        $logger->addInfo("Done queuing split job for commit [$commit]");

    } elseif ('create' === $githubEvent && 'tag' === $jsonContent->ref_type) {

        /**
         * There is a new tag on the master ref,
         * we should create new tag in all repos
         */
        $tag = $jsonContent->ref;
        $logger->addInfo("Github event [$githubEvent]. New tag [$tag]. ");

        // Adding $tag to the work queue
        try {
            $redis->rpush('github-tag-queue', $tag);
        } catch (ConnectionException $e) {
            $logger->addError('Unable to connect to redis: ' . $e->getMessage());
            exit -1;
        }

        $logger->addInfo("Done applying tag [$tag]");

    }
} else {
    $logger->addInfo("Could not parse JSON payload");
    exit -1;
}

/**
 * Securely compares two strings to avoid a time based attack.
 *
 * @see http://codereview.stackexchange.com/questions/13512/constant-time-string-comparision-in-php-to-prevent-timing-attacks
 * @see http://rubydoc.info/github/rack/rack/master/Rack/Utils.secure_compare
 *
 * @param string $original    the known string
 * @param string $destination the string to compare to
 *
 * @return boolean
 */
function secureCompare($original, $destination)
{
    if (strlen($original) != strlen($destination)) {
        return false;
    }

    $originalSplitted = str_split($original);
    $destinationSplitted = str_split($destination);
    $i = -1;

    $stringsAreEquals = array_reduce(
        $destinationSplitted,
        function ($yieldResult, $currentChar) use ($originalSplitted, &$i) {
            $i++;

            // At first iteration, value of $yieldResult is irrelevant
            return (
            is_null($yieldResult) ? true : $yieldResult
                && $currentChar === $originalSplitted[$i]
            );
        }
    );

    return $stringsAreEquals;
}
