<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesUsers;
use Tests\TestCase;

class FaceTest extends TestCase
{
    use CreatesUsers, RefreshDatabase;

    private function employee(): User
    {
        return $this->makeEmployeeUser('karyawan');
    }

    private function fakeEmbed(?array $embedding = null): array
    {
        return array_map('floatval', $embedding ?? array_fill(0, 128, 0.1));
    }

    public function test_enroll_from_photos_stores_encrypted_templates(): void
    {
        Http::fake([
            '*/embed' => Http::response([
                'model_version' => 'sface-2021dec+yunet-2023mar',
                'embedding' => $this->fakeEmbed([0.1, 0.2, 0.3]),
                'dimension' => 128,
            ], 200),
        ]);

        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'photos' => [UploadedFile::fake()->image('a.jpg'), UploadedFile::fake()->image('b.jpg')],
        ])->assertOk()->assertJsonPath('data.count', 2);

        $this->assertSame(2, DB::table('face_templates')->where('employee_id', $user->employee->id)->count());

        $raw = DB::table('face_templates')->value('embedding');
        $this->assertStringStartsWith('eyJ', $raw); // ciphertext, bukan plaintext
        Http::assertSentCount(2);
    }

    public function test_enroll_from_embeddings_without_photos(): void
    {
        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'embeddings' => [$this->fakeEmbed(), $this->fakeEmbed(array_fill(0, 128, 0.6))],
            'model_version' => 'sface-2021dec+yunet-2023mar',
        ])->assertOk()->assertJsonPath('data.count', 2);

        Http::assertNothingSent();
    }

    public function test_enroll_no_face_returns_422(): void
    {
        Http::fake(['*/embed' => Http::response(['detail' => 'no_face'], 422)]);

        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'photos' => [UploadedFile::fake()->image('a.jpg')],
        ])->assertStatus(422)->assertJsonPath('message', 'Wajah tidak terdeteksi.');
    }

    public function test_enroll_multiple_faces_returns_422(): void
    {
        Http::fake(['*/embed' => Http::response(['detail' => 'multiple_faces'], 422)]);

        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'photos' => [UploadedFile::fake()->image('a.jpg')],
        ])->assertStatus(422)->assertJsonPath('message', 'Terdeteksi lebih dari satu wajah.');
    }

    public function test_download_own_template(): void
    {
        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'embeddings' => [$this->fakeEmbed()],
            'model_version' => 'sface-2021dec+yunet-2023mar',
        ])->assertOk();

        $this->actingAs($user, 'sanctum')->getJson('/api/face/template')
            ->assertOk()
            ->assertJsonPath('data.model_version', 'sface-2021dec+yunet-2023mar')
            ->assertJsonCount(1, 'data.embeddings');

        $this->assertCount(128, $this->actingAs($user, 'sanctum')->getJson('/api/face/template')->json('data.embeddings.0'));
    }

    public function test_verify_uses_face_service_and_returns_best_score(): void
    {
        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/enroll', [
            'embeddings' => [$this->fakeEmbed()],
            'model_version' => 'sface-2021dec+yunet-2023mar',
        ]);

        Http::fake([
            '*/verify' => Http::response([
                'model_version' => 'sface-2021dec+yunet-2023mar',
                'score' => 0.72,
                'threshold' => 0.363,
                'match' => true,
            ], 200),
        ]);

        $this->actingAs($user, 'sanctum')->post('/api/face/verify', [
            'photo' => UploadedFile::fake()->image('live.jpg'),
        ])->assertOk()
            ->assertJsonPath('data.match', true)
            ->assertJsonPath('data.score', 0.72);
    }

    public function test_verify_without_template_returns_422(): void
    {
        $user = $this->employee();

        $this->actingAs($user, 'sanctum')->post('/api/face/verify', [
            'photo' => UploadedFile::fake()->image('live.jpg'),
        ])->assertStatus(422)->assertJsonPath('message', 'Wajah belum terdaftar.');
    }

    public function test_enroll_requires_authentication(): void
    {
        $this->postJson('/api/face/enroll', ['embeddings' => [$this->fakeEmbed()]])
            ->assertStatus(401);
    }
}
