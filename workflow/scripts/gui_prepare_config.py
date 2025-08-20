import os
import glob
import sys
import yaml
from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QVBoxLayout, QFormLayout,
    QLineEdit, QScrollArea, QPushButton, QMessageBox, QGroupBox, QHBoxLayout
)
from PyQt5.QtCore import Qt

# --- Added for quoting only parameter values ---
class QuotedString(str):
    pass

def quoted_str_representer(dumper, data):
    return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='"')

yaml.add_representer(QuotedString, quoted_str_representer)
# -------------------------------------------------

# --- Added to quote sample keys only ---
class QuotedKeyDict(dict):
    pass

def quoted_key_dict_representer(dumper, data):
    value = []
    for item_key, item_value in data.items():
        # Quote keys in samples section
        node_key = dumper.represent_scalar('tag:yaml.org,2002:str', item_key, style='"')
        node_value = dumper.represent_data(item_value)
        value.append((node_key, node_value))
    return yaml.nodes.MappingNode('tag:yaml.org,2002:map', value)

yaml.add_representer(QuotedKeyDict, quoted_key_dict_representer)
# ---------------------------------------------------------------

# Default parameters
default_parameters = {
    "SG": {
        "trimmomatic": "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10",
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "contig_len_filt": "-m 1000",
        "pep_len_filt": "-m 10 -M 50"
    },
    "ST": {
        "trimmomatic": "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10",
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "contig_len_filt": "-m 1000",
        "pep_len_filt": "-m 10 -M 50"
    },
    "MG": {
        "trimmomatic": "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10",
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "contig_len_filt": "-m 1000",
        "pep_len_filt": "-m 10 -M 50"
    },
    "MT": {
        "trimmomatic": "SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:resources/adapters.fa:2:30:10",
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "contig_len_filt": "-m 1000",
        "pep_len_filt": "-m 10 -M 50"
    },
    "CO": {
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "contig_len_filt": "-m 1000",
        "pep_len_filt": "-m 10 -M 50"
    },
    "PE": {
        "min_consensus_pred": "1",
        "anticp2": "-d 2",
        "pep_len_filt": "-m 10 -M 50"
    }
}

# Friendly labels for GUI parameters
friendly_labels = {
    "contig_len_filt": "Minimum Contig Length (bp)",
    "min_pep_len": "Minimum Peptide Length (aa)",
    "max_pep_len": "Maximum Peptide Length (aa)",
    "anticp2": "AntiCP2 Model",
    "min_consensus_pred": "Minimum Number of Tools Confirming Prediction"
}


def detect_input_type():
    base = "data"
    types = {
        "SG": glob.glob(os.path.join(base, "SG", "*.fastq.gz")),
        "ST": glob.glob(os.path.join(base, "ST", "*.fastq.gz")),
        "MG": glob.glob(os.path.join(base, "MG", "*.fastq.gz")),
        "MT": glob.glob(os.path.join(base, "MT", "*.fastq.gz")),
        "CO": glob.glob(os.path.join(base, "contigs", "*.fasta")),
        "PE": glob.glob(os.path.join(base, "peptides", "*.fasta"))
    }
    for t, files in types.items():
        if files:
            return t
    return None


class ConfigGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("MetaPepticon Config Generator")
        self.resize(800, 600)

        self.input_type = detect_input_type()
        if not self.input_type:
            QMessageBox.critical(self, "Error", "No data found in data/ directory.")
            sys.exit(1)

        self.entries = {}
        self.sample_entries = {}

        self.layout = QVBoxLayout()
        self.setLayout(self.layout)

        self.layout.addWidget(QLabel(f"<h3>Detected input_type: {self.input_type}</h3>"))

        self.setup_parameter_section()
        self.setup_sample_section()
        self.setup_save_button()

    def setup_parameter_section(self):
        group = QGroupBox("Parameters")
        main_form = QFormLayout()

        # Create a separate group box for Trimmomatic parameters
        if "trimmomatic" in default_parameters[self.input_type]:
            seq_filter_group = QGroupBox("Sequence Filtering Options")
            seq_filter_form = QFormLayout()

            # Parse Trimmomatic defaults
            trimmomatic_val = default_parameters[self.input_type]["trimmomatic"]
            parts = trimmomatic_val.split()
            slidingwindow_val = "4:20"
            minlen_val = "25"
            illuminaclip_file = "resources/adapters.fa"
            seed_mismatches = "2"
            palindrome_clip_threshold = "30"
            simple_clip_threshold = "10"

            for part in parts:
                if part.startswith("SLIDINGWINDOW:"):
                    slidingwindow_val = part[len("SLIDINGWINDOW:"):]
                elif part.startswith("MINLEN:"):
                    minlen_val = part[len("MINLEN:"):]
                elif part.startswith("ILLUMINACLIP:"):
                    illum_params = part[len("ILLUMINACLIP:"):].split(":")
                    if len(illum_params) == 4:
                        illuminaclip_file = illum_params[0]
                        seed_mismatches = illum_params[1]
                        palindrome_clip_threshold = illum_params[2]
                        simple_clip_threshold = illum_params[3]

            self.entries["trimmomatic_slidingwindow"] = QLineEdit(slidingwindow_val)
            self.entries["trimmomatic_minlen"] = QLineEdit(minlen_val)
            self.entries["trimmomatic_illuminaclip_file"] = QLineEdit(illuminaclip_file)
            self.entries["trimmomatic_seed_mismatches"] = QLineEdit(seed_mismatches)
            self.entries["trimmomatic_palindrome_clip_threshold"] = QLineEdit(palindrome_clip_threshold)
            self.entries["trimmomatic_simple_clip_threshold"] = QLineEdit(simple_clip_threshold)

            seq_filter_form.addRow(QLabel("Sliding window (windowSize:quality)"), self.entries["trimmomatic_slidingwindow"])
            seq_filter_form.addRow(QLabel("Minimum length"), self.entries["trimmomatic_minlen"])
            seq_filter_form.addRow(QLabel("Adapter file (ILLUMINACLIP)"), self.entries["trimmomatic_illuminaclip_file"])
            seq_filter_form.addRow(QLabel("Seed mismatches"), self.entries["trimmomatic_seed_mismatches"])
            seq_filter_form.addRow(QLabel("Palindrome clip threshold"), self.entries["trimmomatic_palindrome_clip_threshold"])
            seq_filter_form.addRow(QLabel("Simple clip threshold"), self.entries["trimmomatic_simple_clip_threshold"])

            seq_filter_group.setLayout(seq_filter_form)
            # Add the Sequence Filtering Options group box to the main form layout
            main_form.addRow(seq_filter_group)

        # Add the rest of parameters except trimmomatic and pep_len_filt
        for key, value in default_parameters[self.input_type].items():
            if key in ["trimmomatic", "pep_len_filt"]:
                continue
            entry = QLineEdit()
            if key == "contig_len_filt" and value.startswith("-m "):
                display_value = value[3:]
            elif key == "anticp2" and value.startswith("-d "):
                display_value = value[3:]
            else:
                display_value = value

            entry.setText(display_value)
            label_text = friendly_labels.get(key, key)
            self.entries[key] = entry
            main_form.addRow(QLabel(label_text), entry)

        # Add pep_len_filt parameters
        pep_val = default_parameters[self.input_type].get("pep_len_filt", "-m 10 -M 50")
        parts = pep_val.split()
        min_pep = parts[1] if "-m" in parts else "10"
        max_pep = parts[3] if "-M" in parts else "50"

        min_entry = QLineEdit(min_pep)
        max_entry = QLineEdit(max_pep)

        self.entries["min_pep_len"] = min_entry
        self.entries["max_pep_len"] = max_entry

        main_form.addRow(QLabel(friendly_labels["min_pep_len"]), min_entry)
        main_form.addRow(QLabel(friendly_labels["max_pep_len"]), max_entry)

        group.setLayout(main_form)
        self.layout.addWidget(group)

    def setup_sample_section(self):
        group = QGroupBox("Samples")
        layout = QVBoxLayout()

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll_content = QWidget()
        scroll_layout = QFormLayout()

        self.sample_entries = self.get_sample_entries()

        for sample, val in self.sample_entries.items():
            entry = QLineEdit()
            entry.setText(val)
            entry.setReadOnly(True)  # <-- Make samples read-only
            self.sample_entries[sample] = entry
            scroll_layout.addRow(QLabel(sample), entry)

        scroll_content.setLayout(scroll_layout)
        scroll.setWidget(scroll_content)
        layout.addWidget(scroll)
        group.setLayout(layout)
        self.layout.addWidget(group)

    def get_sample_entries(self):
        sample_dict = {}
        base = "data"
        folder = self.input_type if self.input_type not in ["CO", "PE"] else "contigs" if self.input_type == "CO" else "peptides"

        if self.input_type in ["SG", "ST", "MG", "MT"]:
            for file in glob.glob(os.path.join(base, folder, "*_1.fastq.gz")):
                base_name = os.path.basename(file).replace("_1.fastq.gz", "")
                r1 = os.path.join(base, folder, f"{base_name}_1.fastq.gz")
                r2 = os.path.join(base, folder, f"{base_name}_2.fastq.gz")
                if os.path.exists(r2):
                    sample_dict[base_name] = f"[r1: \"{r1}\", r2: \"{r2}\"]"
                else:
                    sample_dict[base_name] = f"[r1: \"{r1}\"]"
        elif self.input_type == "CO" or self.input_type == "PE":
            for file in glob.glob(os.path.join(base, folder, "*.fasta")):
                base_name = os.path.basename(file).replace(".fasta", "")
                sample_dict[base_name] = f"\"{file}\""
        return sample_dict

    def setup_save_button(self):
        btn_layout = QHBoxLayout()
        btn = QPushButton("Save config.yaml")
        btn.clicked.connect(self.save_config)
        btn_layout.addStretch()
        btn_layout.addWidget(btn)
        self.layout.addLayout(btn_layout)

    def save_config(self):
        parameters = {}

        # Construct trimmomatic string from inputs
        if "trimmomatic_slidingwindow" in self.entries:
            slidingwindow_val = self.entries["trimmomatic_slidingwindow"].text()
            minlen_val = self.entries["trimmomatic_minlen"].text()
            illum_file = self.entries["trimmomatic_illuminaclip_file"].text()
            seed_mismatches = self.entries["trimmomatic_seed_mismatches"].text()
            palindrome_clip_threshold = self.entries["trimmomatic_palindrome_clip_threshold"].text()
            simple_clip_threshold = self.entries["trimmomatic_simple_clip_threshold"].text()

            trimmomatic_str = (
                f"SLIDINGWINDOW:{slidingwindow_val} MINLEN:{minlen_val} "
                f"ILLUMINACLIP:{illum_file}:{seed_mismatches}:{palindrome_clip_threshold}:{simple_clip_threshold}"
            )
            parameters["trimmomatic"] = QuotedString(trimmomatic_str)

        for k, v in self.entries.items():
            # Skip trimmomatic since handled above
            if k.startswith("trimmomatic_"):
                continue
            parameters[k] = QuotedString(str(v.text()))  # quote parameter values

        # Handle contig_len_filt
        if "contig_len_filt" in parameters and not parameters["contig_len_filt"].startswith("-m "):
            parameters["contig_len_filt"] = QuotedString("-m " + parameters["contig_len_filt"])

        # Add -d prefix back to anticp2
        if "anticp2" in parameters and not parameters["anticp2"].startswith("-d "):
            parameters["anticp2"] = QuotedString("-d " + parameters["anticp2"])

        # Combine pep_len_filt
        min_pep = parameters.pop("min_pep_len", "10")
        max_pep = parameters.pop("max_pep_len", "50")
        parameters["pep_len_filt"] = QuotedString(f"-m {min_pep} -M {max_pep}")

        # Prepare samples dictionary with quoted keys and raw string values
        samples_dict = QuotedKeyDict()
        for sample, entry in self.sample_entries.items():
            samples_dict[sample] = entry.text()

        config = {
            "input_type": QuotedString(self.input_type),  # quote input_type value only
            "parameters": parameters,
            "Samples": samples_dict
        }

        os.makedirs("config", exist_ok=True)
        save_path = os.path.join("config", "config.yaml")

        with open(save_path, "w") as f:
            yaml.dump(config, f, default_flow_style=False, allow_unicode=True)

        QMessageBox.information(self, "Saved", f"Configuration saved to:\n{save_path}")
        self.close()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    gui = ConfigGUI()
    gui.show()
    sys.exit(app.exec_())
