<?php

require __DIR__.'/vendor/autoload.php';

$app = require __DIR__.'/bootstrap/app.php';
$kernel = $app->make(\Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "service_account_exists=".((string) config('services.fcm.service_account_json'))."\n";
echo "project_id=".((string) config('services.fcm.project_id'))."\n";

try {
    $token = app(\App\Services\FcmService::class)->accessToken();
    echo "ACCESS_OK len=".strlen($token)."\n";
} catch (\Throwable $e) {
    echo "ACCESS_ERR: ".$e->getMessage()."\n";
}

echo "push_tokens: ".\App\Models\PushToken::with('user')->count()."\n";
foreach (\App\Models\PushToken::with('user')->latest('id')->limit(5)->get() as $pt) {
    echo "  user_id={$pt->user_id} email={$pt->user->email} tok=".substr($pt->token, 0, 24)."\n";
}
