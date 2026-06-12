const state = {
  summary: null,
  plots: [],
  samples: [],
};

const formatNumber = (value, digits = 3) => {
  const number = Number(value);
  if (!Number.isFinite(number)) return "n/a";
  return number.toFixed(digits).replace(/\.?0+$/, "");
};

const labelVersion = (version) => ({
  cuda_naive_global_memory: "Naive",
  cuda_shared_memory_tiled: "Shared memory",
  cuda_shared_constant_filter: "Shared + constant",
  cuda_multi_output: "Multi-output",
  cuda_register_tiled: "Register tiled",
  cuda_separable: "Separable",
}[version] || version || "n/a");

const card = (label, value, detail = "") => `
  <article class="card">
    <div class="label">${label}</div>
    <div class="value">${value}</div>
    <div class="detail">${detail}</div>
  </article>
`;

function setMode(mode) {
  document.querySelectorAll(".tab").forEach((button) => {
    button.classList.toggle("active", button.dataset.mode === mode);
  });
  document.getElementById("dashboardMode").classList.toggle("active", mode === "dashboard");
  document.getElementById("liveMode").classList.toggle("active", mode === "live");
}

function renderStatusPills(gpus) {
  const container = document.getElementById("statusPills");
  container.innerHTML = gpus.map((gpu) => `
    <span class="pill ${gpu.failed_rows === 0 ? "ok" : ""}">
      ${gpu.label}: ${gpu.timing_rows} rows, ${gpu.failed_rows} failures
    </span>
  `).join("");
}

function bestDetail(best) {
  if (!best) return "No data";
  const version = best.best_kernel_time_version || best.version;
  const width = best.image_width || "";
  const filter = best.filter_size ? `${best.filter_size}x${best.filter_size}` : "";
  const type = best.filter_type || "";
  const block = best.best_kernel_block_width
    ? `${best.best_kernel_block_width}x${best.best_kernel_block_height}`
    : `${best.block_width || ""}x${best.block_height || ""}`;
  return `${labelVersion(version)} | ${width}x${width} | ${filter} ${type} | ${block}`;
}

function renderDirectRows(rows) {
  if (!rows || !rows.length) {
    return `<tr><td colspan="6">No direct-comparison rows found.</td></tr>`;
  }
  return rows.map((row) => `
    <tr>
      <td>${labelVersion(row.version)}</td>
      <td>${formatNumber(row.cpu_time_ms)}</td>
      <td>${formatNumber(row.gpu_kernel_time_ms)}</td>
      <td>${formatNumber(row.gpu_total_time_ms)}</td>
      <td>${formatNumber(row.kernel_speedup)}x</td>
      <td>${row.passed === "true" ? "pass" : "fail"}</td>
    </tr>
  `).join("");
}

function renderDirectComparisons(comparisons) {
  const container = document.getElementById("directComparisonTables");
  const entries = comparisons && comparisons.length
    ? comparisons
    : [{ label: "GTX 1650", case: "4096x4096, 11x11 Sobel-like, 32x16 block", rows: state.summary?.version_comparison || [] }];

  container.innerHTML = entries.map((comparison) => `
    <article class="comparison-card">
      <h3>${comparison.label}</h3>
      <p>${comparison.case}</p>
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Version</th>
              <th>CPU ms</th>
              <th>Kernel ms</th>
              <th>Total ms</th>
              <th>Kernel speedup</th>
              <th>Passed</th>
            </tr>
          </thead>
          <tbody>${renderDirectRows(comparison.rows)}</tbody>
        </table>
      </div>
    </article>
  `).join("");
}

function renderSummary(summary) {
  const [gtx, rtx] = summary.gpus;
  document.getElementById("methodNote").textContent = summary.method_note;
  renderStatusPills(summary.gpus);
  document.getElementById("summaryCards").innerHTML = [
    card("GTX 1650 correctness", `${gtx.failed_rows} failed`, `${gtx.timing_rows} timing rows`),
    card("RTX 4070 correctness", `${rtx.failed_rows} failed`, `${rtx.timing_rows} timing rows`),
    card("GTX 1650 best kernel", `${formatNumber(gtx.best_kernel?.best_kernel_speedup)}x`, bestDetail(gtx.best_kernel)),
    card("GTX 1650 best total", `${formatNumber(gtx.best_total?.best_total_speedup)}x`, bestDetail(gtx.best_total)),
    card("RTX 4070 best kernel", `${formatNumber(rtx.best_kernel?.best_kernel_speedup)}x`, bestDetail(rtx.best_kernel)),
    card("RTX 4070 best total", `${formatNumber(rtx.best_total?.best_total_speedup)}x`, bestDetail(rtx.best_total)),
  ].join("");
  renderDirectComparisons(summary.direct_comparisons);
}

function renderPlots(plots) {
  document.getElementById("plotGrid").innerHTML = plots.map((plot) => `
    <article class="plot-card">
      <h3>${plot.title}</h3>
      <p>${plot.gpu}</p>
      <img src="${plot.url}" alt="${plot.title}" loading="lazy" />
    </article>
  `).join("");
}

function renderSamples(samples) {
  const grid = document.getElementById("sampleGrid");
  if (!samples.length) {
    grid.innerHTML = "<p>No fallback samples found.</p>";
    return;
  }
  const descriptions = {
    Building: "Sobel edge output. The goal is to expose building edges and texture, not preserve the full photo brightness.",
    "Portrait Gaussian": "Gaussian blur output. The face should remain recognizable but smoother and less detailed.",
    "Portrait Sharpen": "Sharpen output. Local contrast increases; depending on normalization it may look darker than the original.",
    Texture: "Sobel edge output. Strong wood-grain transitions become relief-like edge structures.",
  };
  grid.innerHTML = samples.map((sample) => `
    <article class="sample-card">
      <h3>${sample.name}</h3>
      <p class="sample-note">${descriptions[sample.name] || "Filtered convolution output."}</p>
      <div class="sample-images">
        <div>
          <p>Original</p>
          <img src="${sample.original_url}" alt="${sample.name} original" />
        </div>
        <div>
          <p>Output</p>
          <img src="${sample.output_url}" alt="${sample.name} output" />
        </div>
      </div>
    </article>
  `).join("");
}

function metricValue(metrics, ...keys) {
  for (const key of keys) {
    if (metrics && metrics[key] !== undefined) return metrics[key];
  }
  return undefined;
}

function renderLiveResult(result) {
  const metrics = result.metrics || {};
  const kernelTime = metricValue(metrics, "gpu_kernel_time_ms", "kernel_time_ms");
  document.getElementById("liveMetrics").innerHTML = [
    card("Dimensions", `${result.width}x${result.height}`, result.resized ? "resized for demo stability" : "uploaded size"),
    card("CPU time", `${formatNumber(metrics.cpu_time_ms)} ms`, "single-threaded reference"),
    card("Kernel time", `${formatNumber(kernelTime)} ms`, labelVersion(result.version)),
    card("Total GPU time", `${formatNumber(metrics.gpu_total_time_ms)} ms`, "allocation + copies + kernel"),
    card("Kernel speedup", `${formatNumber(metrics.kernel_speedup)}x`, "CPU / kernel time"),
    card("Correctness", metrics.passed ? "passed" : "failed", `max error ${formatNumber(metrics.max_abs_error, 6)}`),
  ].join("");

  document.getElementById("imageCompare").innerHTML = `
    <div class="image-frame">
      <h3>Original</h3>
      <img src="${result.original_url}" alt="Original uploaded image" />
    </div>
    <div class="image-frame">
      <h3>Filtered Output</h3>
      <img src="${result.output_url}" alt="CUDA filtered output" />
    </div>
  `;
  document.getElementById("commandBox").textContent = result.command || "No command captured.";
  document.getElementById("stdoutBox").textContent = result.stdout || "No output captured.";
}

async function loadDashboard() {
  const [summaryResponse, plotResponse, sampleResponse] = await Promise.all([
    fetch("/api/summary"),
    fetch("/api/plots"),
    fetch("/api/sample-demo"),
  ]);
  state.summary = await summaryResponse.json();
  state.plots = (await plotResponse.json()).plots || [];
  state.samples = (await sampleResponse.json()).samples || [];
  renderSummary(state.summary);
  renderPlots(state.plots);
  renderSamples(state.samples);
}

function setupLiveForm() {
  const imageInput = document.getElementById("imageInput");
  const fileName = document.getElementById("fileName");
  const form = document.getElementById("demoForm");
  const message = document.getElementById("liveMessage");

  imageInput.addEventListener("change", () => {
    fileName.textContent = imageInput.files[0]?.name || "No file selected";
  });

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    message.className = "message";
    message.textContent = "Running CUDA executable...";

    const formData = new FormData(form);
    try {
      const response = await fetch("/api/run-demo", {
        method: "POST",
        body: formData,
      });
      const result = await response.json();
      if (!response.ok || !result.ok) {
        throw new Error(result.error || "Live demo failed.");
      }
      message.className = "message ok";
      message.textContent = "CUDA demo completed successfully.";
      renderLiveResult(result);
    } catch (error) {
      message.className = "message error";
      message.textContent = `${error.message} Dashboard and fallback outputs remain available.`;
    }
  });
}

document.addEventListener("DOMContentLoaded", async () => {
  document.querySelectorAll(".tab").forEach((button) => {
    button.addEventListener("click", () => setMode(button.dataset.mode));
  });
  setupLiveForm();
  try {
    await loadDashboard();
  } catch (error) {
    document.getElementById("statusPills").innerHTML =
      `<span class="pill">${error.message}</span>`;
  }
});
