<?php

require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$kernel = $app->make(\Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

echo "jobs=".DB::table('jobs')->count()."\n";
echo "failed_jobs=".DB::table('failed_jobs')->count()."\n";
$n = \App\Models\Notification::orderByDesc('id')->first();
if ($n) {
    echo "latest_notif id={$n->id} user_id={$n->user_id} type={$n->data_json['type']} dedupe={$n->dedupe_key} created={$n->created_at->toDateTimeString()}\n";
    echo "token_count={$n->user->pushTokens()->count()}\n";
}
// accessToken private via reflection (validasi service account)
try {
    $fcm = app(\App\Services\FcmService::class);
    $r = new \ReflectionMethod($fcm, 'accessToken');
    $r->setAccessible(true);
    $t = $r->invoke($fcm);
    echo "ACCESS_OK len=".strlen($t)."\n";
} catch (\Throwable $e) {
    echo "ACCESS_ERR: ".$e->getMessage()."\n";
}
