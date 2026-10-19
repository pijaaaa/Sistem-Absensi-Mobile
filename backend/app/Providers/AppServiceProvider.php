<?php

namespace App\Providers;

use App\Models\Employee;
use App\Observers\EmployeeObserver;
use App\Support\Access\PermissionService;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(PermissionService::class);
    }

    public function boot(): void
    {
        Employee::observe(EmployeeObserver::class);

        // Gerbang izin: setiap ability berformat "modul.aksi" dicek dari tabel izin.
        Gate::before(function ($user, string $ability) {
            if ($user->isSuperadmin()) {
                return true;
            }

            if (! str_contains($ability, '.')) {
                return null;
            }

            $service = app(PermissionService::class);

            if (! in_array($ability, $service->allKeys(), true)) {
                return null;
            }

            return $service->userHas($user, $ability);
        });
    }
}
