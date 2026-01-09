package stages

import (
	"context"
	"fmt"

	"github.com/daveweinstein1/strix-installer/pkg/core"
	"github.com/daveweinstein1/strix-installer/pkg/system"
)

// ThermalStage installs fan control and thermal monitoring tools
type ThermalStage struct{}

func NewThermalStage() *ThermalStage { return &ThermalStage{} }

func (s *ThermalStage) ID() string   { return "thermal" }
func (s *ThermalStage) Name() string { return "Fan & Thermal Control" }
func (s *ThermalStage) Description() string {
	return "Install lm_sensors and fancontrol for case fan management"
}
func (s *ThermalStage) Optional() bool { return true }

func (s *ThermalStage) Run(ctx context.Context, ui core.UI) error {
	pacman := system.NewPacman()

	// Step 1: Install thermal packages
	ui.Progress(10, "Installing thermal monitoring packages...")
	packages := []string{
		"lm_sensors",
		"fancontrol",
	}

	if err := pacman.Install(ctx, packages...); err != nil {
		return fmt.Errorf("failed to install thermal packages: %v", err)
	}
	ui.Log(core.LogInfo, "✓ lm_sensors and fancontrol installed")

	// Step 2: Run sensors-detect (non-interactive, accept defaults)
	ui.Progress(40, "Detecting temperature sensors...")
	result, err := system.ExecShellSudo(ctx, "yes '' | sensors-detect --auto")
	if err != nil {
		ui.Log(core.LogWarn, fmt.Sprintf("sensors-detect had issues: %v", err))
	} else {
		ui.Log(core.LogInfo, "✓ Sensors detected")
		_ = result
	}

	// Step 3: Load detected modules
	ui.Progress(60, "Loading sensor modules...")
	_, _ = system.ExecSudo(ctx, "systemctl", "restart", "systemd-modules-load")

	// Step 4: Test sensors
	ui.Progress(75, "Testing sensors...")
	result, err = system.Exec(ctx, "sensors")
	if err != nil {
		ui.Log(core.LogWarn, "Could not read sensors")
	} else {
		// Just log that it works
		ui.Log(core.LogInfo, "✓ Sensors responding")
	}

	// Step 5: Note about fancontrol
	ui.Progress(90, "Fan control ready...")
	ui.Log(core.LogInfo, "")
	ui.Log(core.LogInfo, "To configure fan curves, run:")
	ui.Log(core.LogInfo, "  sudo pwmconfig")
	ui.Log(core.LogInfo, "Then enable the service:")
	ui.Log(core.LogInfo, "  sudo systemctl enable --now fancontrol")
	ui.Log(core.LogInfo, "")

	ui.Progress(100, "Thermal setup complete")
	return nil
}

func (s *ThermalStage) Rollback(ctx context.Context) error {
	return nil
}
