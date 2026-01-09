package main

import (
	"fmt"
	// Import the cmd/tui model if possible, but it's in main package.
	// We might have to duplicate the model logic slightly or move main.MarketplaceModel to pkg/ui/marketplace.go?
	// The View() logic is simple enough to replicate for the screenshot if model is not exported.
)

func main() {
	// Replicating the View logic from cmd/tui/marketplace.go since it's in 'main' package and not importable
	// Ideally we'd move it to pkg/ui, but for this task I'll just reconstruct the exact string.

	// Header
	s := "Container Marketplace\n"
	s += "──────────────────────\n\n"

	// List
	s += "> amd-strix-halo-toolboxes\n"
	s += "  comfyui-rocm (amd-official)\n"
	s += "  strix-playground (community)\n\n"

	// Footer (Details)
	s += "──────────────────────\n"
	s += "source: kyuz0 | Community Strix Halo toolboxes (ROCm, LLaMA, PyTorch)\n"
	s += "url: ghcr.io/kyuz0/amd-strix-halo-toolboxes\n\n"

	s += "• Select   ↑/↓ Move   q Quit"

	fmt.Println(s)
}
