<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lateness_rules', function (Blueprint $table) {
            $table->id();
            $table->string('label');
            $table->unsignedInteger('from_minute')->default(0);
            $table->unsignedInteger('to_minute')->nullable();
            $table->string('color')->default('gray');
            $table->boolean('is_counted_late')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lateness_rules');
    }
};
