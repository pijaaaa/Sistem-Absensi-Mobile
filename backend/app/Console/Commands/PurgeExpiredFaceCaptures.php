<?php

namespace App\Console\Commands;

use App\Models\FaceCapture;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

#[Signature('app:purge-expired-face-captures')]
#[Description('Hapus foto crop wajah yang sudah melewati expires_at (file + baris).')]
class PurgeExpiredFaceCaptures extends Command
{
    public function handle(): int
    {
        $expired = FaceCapture::where('expires_at', '<', now())->get();

        foreach ($expired as $capture) {
            Storage::disk('local')->delete($capture->path);
            $capture->delete();
        }

        $this->info('Dihapus: '.$expired->count());

        return self::SUCCESS;
    }
}
