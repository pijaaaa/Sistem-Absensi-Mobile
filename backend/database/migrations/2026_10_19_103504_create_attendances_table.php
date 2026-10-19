<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->date('date');
            $table->timestamp('check_in_at')->nullable();
            $table->timestamp('check_out_at')->nullable();
            $table->double('in_lat')->nullable();
            $table->double('in_lng')->nullable();
            $table->double('out_lat')->nullable();
            $table->double('out_lng')->nullable();
            $table->foreignId('location_id')->nullable()->constrained('work_locations')->nullOnDelete();
            $table->unsignedInteger('late_minutes')->default(0);
            $table->string('late_level')->nullable();
            $table->unsignedInteger('early_leave_minutes')->default(0);
            $table->boolean('is_dinas')->default(false);
            $table->boolean('is_offline')->default(false);
            $table->enum('time_trust', ['ok', 'suspect'])->default('ok');
            $table->uuid('client_uuid')->nullable()->unique();
            $table->foreignId('device_id')->nullable()->constrained('devices')->nullOnDelete();
            $table->boolean('is_backup_device')->default(false);
            $table->enum('approval_status', ['none', 'pending', 'approved', 'rejected'])->default('none');
            $table->foreignId('approver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->float('face_score_local')->nullable();
            $table->float('face_score_server')->nullable();
            $table->boolean('review_flag')->default(false);
            $table->enum('review_status', ['valid', 'invalid'])->nullable();
            $table->string('review_note')->nullable();
            $table->timestamps();

            $table->unique(['employee_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
