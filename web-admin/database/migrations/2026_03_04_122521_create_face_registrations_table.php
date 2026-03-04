<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('face_registrations', function (Blueprint $table) {
            $table->id();
            $table->string('token')->unique();
            $table->boolean('is_used')->default(false);
            $table->string('name')->nullable();
            $table->string('nia', 7)->nullable();
            $table->json('face_embedding')->nullable();
            $table->text('address')->nullable();
            $table->date('birth_date')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('face_registrations');
    }
};
