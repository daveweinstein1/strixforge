package core

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"
)

// State tracks what has been installed
type State struct {
	FirstRunComplete bool      `json:"firstRunComplete"`
	InstalledStages  []string  `json:"installedStages"`
	SkippedStages    []string  `json:"skippedStages"`
	Timestamp        time.Time `json:"timestamp"`
	DeviceName       string    `json:"deviceName"`
	InstallerVersion string    `json:"installerVersion"`
}

// StateManager handles persistent state
type StateManager struct {
	path  string
	state *State
}

// NewStateManager creates a state manager for the current user
func NewStateManager() *StateManager {
	home, _ := os.UserHomeDir()
	path := filepath.Join(home, ".config", "strix-install", "state.json")

	return &StateManager{
		path:  path,
		state: &State{},
	}
}

// Load reads state from disk
func (m *StateManager) Load() error {
	data, err := os.ReadFile(m.path)
	if err != nil {
		if os.IsNotExist(err) {
			// No state file = first run
			m.state = &State{FirstRunComplete: false}
			return nil
		}
		return err
	}

	return json.Unmarshal(data, m.state)
}

// Save writes state to disk
func (m *StateManager) Save() error {
	// Ensure directory exists
	dir := filepath.Dir(m.path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	m.state.Timestamp = time.Now()
	data, err := json.MarshalIndent(m.state, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(m.path, data, 0644)
}

// IsFirstRun returns true if installer hasn't been run before
func (m *StateManager) IsFirstRun() bool {
	return !m.state.FirstRunComplete
}

// MarkFirstRunComplete sets the first run flag
func (m *StateManager) MarkFirstRunComplete() {
	m.state.FirstRunComplete = true
}

// AddInstalledStage records a completed stage
func (m *StateManager) AddInstalledStage(stageID string) {
	// Remove from skipped if present
	m.state.SkippedStages = removeFromSlice(m.state.SkippedStages, stageID)

	// Add to installed if not already there
	if !contains(m.state.InstalledStages, stageID) {
		m.state.InstalledStages = append(m.state.InstalledStages, stageID)
	}
}

// AddSkippedStage records a skipped stage
func (m *StateManager) AddSkippedStage(stageID string) {
	if !contains(m.state.SkippedStages, stageID) {
		m.state.SkippedStages = append(m.state.SkippedStages, stageID)
	}
}

// IsStageInstalled checks if a stage was already run
func (m *StateManager) IsStageInstalled(stageID string) bool {
	return contains(m.state.InstalledStages, stageID)
}

// IsStageSkipped checks if a stage was skipped
func (m *StateManager) IsStageSkipped(stageID string) bool {
	return contains(m.state.SkippedStages, stageID)
}

// GetSkippedStages returns list of skipped stage IDs
func (m *StateManager) GetSkippedStages() []string {
	return m.state.SkippedStages
}

// GetInstalledStages returns list of installed stage IDs
func (m *StateManager) GetInstalledStages() []string {
	return m.state.InstalledStages
}

// SetDeviceName stores the detected device
func (m *StateManager) SetDeviceName(name string) {
	m.state.DeviceName = name
}

// SetVersion stores the installer version
func (m *StateManager) SetVersion(version string) {
	m.state.InstallerVersion = version
}

// helpers
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func removeFromSlice(slice []string, item string) []string {
	result := make([]string, 0, len(slice))
	for _, s := range slice {
		if s != item {
			result = append(result, s)
		}
	}
	return result
}
