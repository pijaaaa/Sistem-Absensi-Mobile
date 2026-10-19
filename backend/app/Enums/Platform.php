<?php

namespace App\Enums;

enum Platform: string
{
    case Web = 'web';
    case Mobile = 'mobile';
    case Both = 'both';
}
