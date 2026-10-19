<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('work_locations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('mode', ['point', 'polygon', 'off'])->default('point');
            $table->double('lat')->nullable();
            $table->double('lng')->nullable();
            $table->unsignedInteger('radius_m')->nullable();
            $table->json('polygon_json')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('work_locations');
    }
};
