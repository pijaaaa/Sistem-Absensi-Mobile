<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\FaceCapture;
use App\Support\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReviewController extends Controller
{
    public function index(Request $request): View
    {
        $status = $request->input('status', 'pending');

        $attendances = Attendance::with(['employee', 'faceCaptures'])
            ->where(function ($q) {
                $q->where('review_flag', true)->orWhere('time_trust', 'suspect');
            })
            ->when($status === 'pending', fn ($q) => $q->whereNull('review_status'))
            ->when(in_array($status, ['valid', 'invalid'], true), fn ($q) => $q->where('review_status', $status))
            ->latest()
            ->paginate(20)
            ->withQueryString();

        return view('review.index', compact('attendances', 'status'));
    }

    public function photo(FaceCapture $faceCapture): StreamedResponse
    {
        abort_unless($faceCapture->expires_at->isFuture(), 404, 'Foto sudah kedaluwarsa.');
        abort_unless(Storage::disk('local')->exists($faceCapture->path), 404);

        return Storage::disk('local')->response($faceCapture->path);
    }

    public function mark(Request $request, Attendance $attendance): RedirectResponse
    {
        $data = $request->validate([
            'review_status' => ['required', 'in:valid,invalid'],
            'review_note' => ['nullable', 'string', 'max:255'],
        ]);

        $old = ['review_status' => $attendance->review_status];

        $attendance->update([
            'review_status' => $data['review_status'],
            'review_note' => $data['review_note'] ?? null,
        ]);

        AuditLogger::record('review.marked', $attendance, $old, ['review_status' => $data['review_status']]);

        return back()->with('status', 'Status review disimpan.');
    }
}
