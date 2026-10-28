<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('face_templates', function (Blueprint $table) {
            $table->string('pose')->default('front')->after('employee_id');
            $table->float('quality_score')->default(1.0)->after('model_version');
        });

        Schema::create('face_attempts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('type'); // in, out, verify
            $table->float('score')->nullable();
            $table->enum('zone', ['pass', 'review', 'reject']);
            $table->text('quality_metrics')->nullable();
            $table->timestamps();
        });

        DB::table('settings')->insertOrIgnore([
            ['key' => 'face_threshold_pass', 'value' => '0.50'],
            ['key' => 'face_threshold_review', 'value' => '0.363'],
            ['key' => 'face_max_attempts', 'value' => '3'],
            ['key' => 'face_lockout_minutes', 'value' => '15'],
        ]);
    }

    public function down(): void
    {
        Schema::table('face_templates', function (Blueprint $table) {
            $table->dropColumn(['pose', 'quality_score']);
        });

        Schema::dropIfExists('face_attempts');

        DB::table('settings')->whereIn('key', [
            'face_threshold_pass',
            'face_threshold_review',
            'face_max_attempts',
            'face_lockout_minutes',
        ])->delete();
    }
};
