<?php

namespace App\Exceptions;

use RuntimeException;

class FaceException extends RuntimeException
{
    public function __construct(public readonly string $errorCode, string $message = '', int $status = 422)
    {
        parent::__construct($message ?: $errorCode, $status);
    }
}
