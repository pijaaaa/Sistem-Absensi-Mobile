<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->string('device_uid');
            $table->string('name')->nullable();
            $table->enum('type', ['primary', 'backup'])->default('primary');
            $table->enum('status', ['active', 'revoked'])->default('active');
            $table->timestamp('registered_at')->nullable();
            $table->timestamps();

            $table->unique(['employee_id', 'device_uid']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
